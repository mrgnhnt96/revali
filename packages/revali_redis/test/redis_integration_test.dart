@Tags(['integration'])
library;

import 'dart:async';
import 'dart:io';

import 'package:revali_core/revali_core.dart';
import 'package:revali_redis/revali_redis.dart';
import 'package:test/test.dart';

/// Where to find a Redis to test against.
///
/// Defaults to the usual port so `redis-server` on a laptop just works, and is
/// overridable so CI can point at a container without editing this file.
final _host = Platform.environment['REDIS_TEST_HOST'] ?? 'localhost';
final _port =
    int.tryParse(Platform.environment['REDIS_TEST_PORT'] ?? '') ?? 6379;

/// Whether a server is actually there.
///
/// Everything below is skipped rather than failed when it is not: a developer
/// without Redis running should still get a green suite, while the tests stay
/// one command away from being real.
Future<bool> _reachable() async {
  try {
    final socket = await Socket.connect(
      _host,
      _port,
      timeout: const Duration(milliseconds: 500),
    );
    socket.destroy();

    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool available;
  late String topic;

  setUpAll(() async {
    available = await _reachable();
  });

  /// Marks the current test skipped when no server is reachable.
  ///
  /// Checked inside each test rather than left to `dart_test.yaml`: the tag
  /// config is honoured by `dart test` but not by every runner this repo
  /// uses, and a suite that fails on a machine without Redis is a suite
  /// people learn to ignore.
  bool hasRedis() {
    if (!available) {
      markTestSkipped('No Redis at $_host:$_port');

      return false;
    }

    return true;
  }

  setUp(() {
    // A fresh stream per test, so nothing inherits another test's entries or
    // consumer groups.
    topic = 'revali-test-${DateTime.now().microsecondsSinceEpoch}';
  });

  Future<RedisBroker> connect({String consumerName = 'revali'}) =>
      RedisBroker.connect(host: _host, port: _port, consumerName: consumerName);

  /// Waits for [condition] rather than sleeping a fixed amount: the read loop
  /// blocks server-side, so timing is not something a test should guess at.
  Future<void> until(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));

    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition never became true');
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  group('against a real Redis', () {
    test('round-trips a message through a stream', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      addTearDown(broker.close);

      final seen = <BrokerMessage>[];
      await broker.subscribe(topic, group: 'g1', onMessage: seen.add);
      await broker.publish(topic, 'placed');

      await until(() => seen.isNotEmpty);

      expect(seen.single.payload, 'placed');
      expect(seen.single.topic, topic);
      // A real stream id, not one this package invented.
      expect(seen.single.id, contains('-'));
    });

    test('carries headers across the wire', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      addTearDown(broker.close);

      final seen = <BrokerMessage>[];
      await broker.subscribe(topic, group: 'g1', onMessage: seen.add);
      await broker.publish(
        topic,
        'placed',
        headers: {'X-Request-Id': 'abc', 'baggage': 'tenant=acme'},
      );

      await until(() => seen.isNotEmpty);

      expect(seen.single.headers, {
        'X-Request-Id': 'abc',
        'baggage': 'tenant=acme',
      });
    });

    test('delivers a message published before anyone subscribed', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      addTearDown(broker.close);

      // MKSTREAM plus a group starting at `$` means a consumer group created
      // after the fact does NOT see earlier entries. Publishing first, then
      // subscribing, then publishing again is the honest check of that.
      await broker.publish(topic, 'before');

      final seen = <BrokerMessage>[];
      await broker.subscribe(topic, group: 'g1', onMessage: seen.add);
      await broker.publish(topic, 'after');

      await until(() => seen.isNotEmpty);

      expect(seen.map((m) => m.payload), ['after']);
    });

    test('separate groups each get their own copy', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      addTearDown(broker.close);

      final billing = <String>[];
      final shipping = <String>[];

      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) => billing.add(m.payload),
      );
      await broker.subscribe(
        topic,
        group: 'shipping',
        onMessage: (m) => shipping.add(m.payload),
      );

      await broker.publish(topic, 'placed');

      await until(() => billing.isNotEmpty && shipping.isNotEmpty);

      // This is what lets a new service react to an event without the
      // publisher being touched.
      expect(billing, ['placed']);
      expect(shipping, ['placed']);
    });

    test('one group shares work between its members', () async {
      if (!hasRedis()) return;

      final broker = await connect(consumerName: 'a');
      final second = await connect(consumerName: 'b');
      addTearDown(broker.close);
      addTearDown(second.close);

      final first = <String>[];
      final other = <String>[];

      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) => first.add(m.payload),
      );
      await second.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) => other.add(m.payload),
      );

      for (var i = 0; i < 10; i++) {
        await broker.publish(topic, '$i');
      }

      await until(() => first.length + other.length == 10);

      // Every message handled exactly once across the group.
      expect({...first, ...other}, hasLength(10));
    });

    test('an unacknowledged message stays pending for redelivery', () async {
      if (!hasRedis()) return;

      final broker = await connect(consumerName: 'flaky');
      addTearDown(broker.close);

      var attempts = 0;
      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (_) {
          attempts++;
          throw StateError('boom');
        },
      );
      await broker.publish(topic, 'placed');

      await until(() => attempts > 0);
      // Give the loop a chance to ack if it were going to.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Redis itself is the assertion here: the entry must still be pending.
      final control = await SocketRedisConnection.connect(_host, _port);
      addTearDown(control.close);

      final pending = await control.send(['XPENDING', topic, 'billing']);

      expect(pending, isA<List<Object?>>());
      expect(
        (pending! as List<Object?>).first,
        1,
        reason: 'one entry still pending',
      );
    });

    test('a handled message is acknowledged', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      addTearDown(broker.close);

      final seen = <String>[];
      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );
      await broker.publish(topic, 'placed');

      await until(() => seen.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final control = await SocketRedisConnection.connect(_host, _port);
      addTearDown(control.close);

      final pending = await control.send(['XPENDING', topic, 'billing']);

      expect(
        (pending! as List<Object?>).first,
        0,
        reason: 'nothing left pending',
      );
    });

    test('survives a payload with CRLF and multi-byte characters', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      addTearDown(broker.close);

      // The two ways a length-prefixed protocol goes wrong: an embedded
      // delimiter, and a byte length that differs from the code-unit length.
      const payload = 'line one\r\nline two — é';

      final seen = <BrokerMessage>[];
      await broker.subscribe(topic, group: 'g1', onMessage: seen.add);
      await broker.publish(topic, payload);

      await until(() => seen.isNotEmpty);

      expect(seen.single.payload, payload);
    });

    test('a consumer group survives a restart of the subscriber', () async {
      if (!hasRedis()) return;

      final first = await connect();
      final subscription = await first.subscribe(
        topic,
        group: 'billing',
        onMessage: (_) {},
      );
      await subscription.cancel();
      await first.close();

      // BUSYGROUP on the second subscribe; treating it as fatal would make
      // every restart after the first fail.
      final second = await connect();
      addTearDown(second.close);

      final seen = <String>[];
      await second.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) => seen.add(m.payload),
      );
      await second.publish(topic, 'after-restart');

      await until(() => seen.isNotEmpty);

      expect(seen, ['after-restart']);
    });

    test('drains in-flight work through the ConsumerRegistry', () async {
      if (!hasRedis()) return;

      final broker = await connect();
      final registry = ConsumerRegistry(broker: broker);

      final release = Completer<void>();
      var finished = false;

      await registry.consume(
        topic,
        group: 'billing',
        onMessage: (_) async {
          await release.future;
          finished = true;
        },
      );
      await broker.publish(topic, 'slow');

      await until(() => registry.inFlight > 0);

      final drained = registry.drain(const Duration(seconds: 5));
      release.complete();

      expect(await drained, isTrue);
      expect(finished, isTrue);

      await registry.close();
    });
  });

  group('reclaiming against a real Redis', () {
    test('recovers an entry a dead consumer abandoned', () async {
      if (!hasRedis()) return;

      // A consumer that reads and never acks, then goes away -- exactly what
      // a pod replacement looks like to Redis.
      final dead = await RedisBroker.connect(
        host: _host,
        port: _port,
        consumerName: 'dead-replica',
      );
      final read = <String>[];
      await dead.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) {
          read.add(m.payload);
          throw StateError('never acknowledges');
        },
      );
      await dead.publish(topic, 'stranded');
      await until(() => read.isNotEmpty);
      await dead.close();

      // Redis tracks pending entries per consumer name, so nothing else would
      // ever see this entry without reclaiming.
      final live = RedisBroker(
        connection: await SocketRedisConnection.connect(_host, _port),
        openConnection: () => _LazyOpen(_host, _port),
        consumerName: 'live-replica',
        blockFor: const Duration(milliseconds: 100),
        claimAfter: Duration.zero,
      );
      addTearDown(live.close);

      final recovered = <String>[];
      await live.subscribe(
        topic,
        group: 'billing',
        onMessage: (m) => recovered.add(m.payload),
      );

      await until(() => recovered.isNotEmpty);

      expect(recovered, contains('stranded'));
    });

    test('dead-letters a message that keeps failing', () async {
      if (!hasRedis()) return;

      final broker = RedisBroker(
        connection: await SocketRedisConnection.connect(_host, _port),
        openConnection: () => _LazyOpen(_host, _port),
        consumerName: 'flaky',
        blockFor: const Duration(milliseconds: 50),
        claimAfter: Duration.zero,
        maxDeliveries: 2,
        // The backoff has its own tests below; here it would only mean
        // sleeping, and a ten-second deadline it barely clears is a flake
        // waiting to happen.
        retryAfter: Duration.zero,
      );
      addTearDown(broker.close);

      var attempts = 0;
      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (_) {
          attempts++;
          throw StateError('poison');
        },
      );
      await broker.publish(topic, 'poison');

      // Redis is the assertion: the message must end up on the dead-letter
      // stream, and stop being retried.
      final control = await SocketRedisConnection.connect(_host, _port);
      addTearDown(control.close);

      var deadLength = 0;
      final deadline = DateTime.now().add(const Duration(seconds: 10));

      while (deadLength == 0) {
        if (DateTime.now().isAfter(deadline)) {
          fail('nothing reached the dead-letter stream');
        }

        final length = await control.send(['XLEN', '$topic.dead']);
        deadLength = length is int ? length : 0;

        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      expect(deadLength, 1);
      expect(
        attempts,
        greaterThan(1),
        reason: 'it was retried before giving up',
      );
    });

    test('delivers exactly maxDeliveries times, then stops', () async {
      if (!hasRedis()) return;

      // Redis owns the delivery counter, so this is the only place the
      // arithmetic can actually be checked. `maxDeliveries: 3` has to mean
      // three attempts -- it used to mean four, because the check fired one
      // delivery past the number it was named for.
      final broker = RedisBroker(
        connection: await SocketRedisConnection.connect(_host, _port),
        openConnection: () => _LazyOpen(_host, _port),
        consumerName: 'counted',
        blockFor: const Duration(milliseconds: 50),
        maxDeliveries: 3,
        retryAfter: Duration.zero,
      );
      addTearDown(broker.close);

      var attempts = 0;
      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (_) {
          attempts++;
          throw StateError('poison');
        },
      );
      await broker.publish(topic, 'poison');

      final control = await SocketRedisConnection.connect(_host, _port);
      addTearDown(control.close);

      final deadline = DateTime.now().add(const Duration(seconds: 10));
      var dead = 0;

      while (dead == 0) {
        if (DateTime.now().isAfter(deadline)) {
          fail('nothing reached the dead-letter stream');
        }

        final length = await control.send(['XLEN', '$topic.dead']);
        dead = length is int ? length : 0;

        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      // Settled: nothing may pick it up again once it is dead-lettered.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(attempts, 3);
    });

    test('waits out retryAfter before redelivering', () async {
      if (!hasRedis()) return;

      // Redis's own idle clock is what the backoff is measured against, so a
      // fake cannot show this holding. Without it, redelivery runs at the
      // speed of the read loop -- here, every 50ms.
      final broker = RedisBroker(
        connection: await SocketRedisConnection.connect(_host, _port),
        openConnection: () => _LazyOpen(_host, _port),
        consumerName: 'patient',
        blockFor: const Duration(milliseconds: 50),
        retryAfter: const Duration(seconds: 2),
      );
      addTearDown(broker.close);

      final attempts = <DateTime>[];
      await broker.subscribe(
        topic,
        group: 'billing',
        onMessage: (_) {
          attempts.add(DateTime.now());
          throw StateError('poison');
        },
      );
      await broker.publish(topic, 'poison');

      await until(() => attempts.length >= 2);

      final gap = attempts[1].difference(attempts[0]);

      expect(
        gap,
        greaterThanOrEqualTo(const Duration(milliseconds: 1900)),
        reason: 'the retry must wait, not fire on the next read',
      );
    });
  });
}

/// Opens a fresh connection per subscription, matching what
/// `RedisBroker.connect` does internally.
class _LazyOpen implements RedisConnection {
  _LazyOpen(this._host, this._port);

  final String _host;
  final int _port;
  Future<RedisConnection>? _opened;

  Future<RedisConnection> get _connection =>
      _opened ??= SocketRedisConnection.connect(_host, _port);

  @override
  Future<Object?> send(List<String> command) async =>
      (await _connection).send(command);

  @override
  Future<void> close() async {
    if (_opened case final opened?) {
      await (await opened).close();
    }
  }
}
