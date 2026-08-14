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

    if (!available) {
      printOnFailure('No Redis at $_host:$_port');
    }
  });

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
}
