import 'dart:async';
import 'dart:io';

import 'package:revali_redis/revali_redis.dart';
import 'package:test/test.dart';

/// Recovery from a Redis server restart.
///
/// Two failures hide behind one event, and they need different handling:
///
///  * the **link** dies -- every socket the server was holding is gone, so the
///    next command throws a `SocketException`; and
///  * the **group** is gone -- once reconnected the socket is perfectly
///    healthy, so nothing looks broken, and every `XREADGROUP` answers
///    `NOGROUP` forever while the consumer sits there apparently fine.
///
/// Found by restarting a real `redis-server` under a running consumer. The
/// original behaviour was worse than "does not reconnect": the write to the
/// dead socket escaped as an unhandled async error and killed the process.
///
/// These use a scripted connection rather than a real server so they run on a
/// machine with no Redis. The real-restart path is exercised by
/// `redis_integration_test.dart`.

/// A connection that fails on demand, and counts how many times it was opened.
class _ScriptedConnection implements RedisConnection {
  _ScriptedConnection(this.generation, this._state);

  final int generation;
  final _SharedState _state;

  bool closed = false;

  @override
  Future<Object?> send(List<String> command) async {
    _state.commands.add('gen$generation:${command.join(' ')}');

    // A real server blocks; returning instantly turns the read loop into a
    // microtask-only spin that starves the timer queue, so nothing using
    // Future.delayed -- including this test's own polling -- ever runs again.
    await Future<void>.delayed(Duration.zero);

    if (_state.failLinkForGeneration.contains(generation)) {
      throw const SocketException('Connection reset by peer');
    }

    if (command.first == 'XGROUP') {
      _state.groupsCreated.add(command.skip(2).take(2).join('/'));

      return 'OK';
    }

    if (command.first == 'XREADGROUP') {
      if (!_state.groupsCreated.contains('${command[9]}/${command[2]}')) {
        throw const RedisError(
          'NOGROUP No such key or consumer group in XREADGROUP',
        );
      }

      return _state.readReply;
    }

    return 'OK';
  }

  @override
  Future<void> close() async => closed = true;
}

class _SharedState {
  final commands = <String>[];
  final groupsCreated = <String>{};
  final failLinkForGeneration = <int>{};
  final openedGenerations = <int>[];

  /// Generations whose *open* should fail, standing in for the window after a
  /// restart where the server is not yet accepting connections.
  final refuseOpenForGeneration = <int>{};

  Object? readReply;
}

void main() {
  group('RedisError.isNoGroup', () {
    test('recognises the reply a lost consumer group produces', () {
      const error = RedisError('NOGROUP No such key or consumer group');

      expect(error.isNoGroup, isTrue);
      expect(error.isBusyGroup, isFalse);
    });

    test('does not mistake another error for it', () {
      const error = RedisError('ERR value is not an integer');

      expect(error.isNoGroup, isFalse);
    });

    test('BUSYGROUP is not NOGROUP', () {
      const error = RedisError('BUSYGROUP Consumer Group name already exists');

      expect(error.isNoGroup, isFalse);
      expect(error.isBusyGroup, isTrue);
    });
  });

  group('server restart', () {
    late _SharedState state;
    var generation = 0;

    RedisConnection open() {
      final next = ++generation;
      state.openedGenerations.add(next);

      if (state.refuseOpenForGeneration.contains(next)) {
        throw const SocketException('Connection refused');
      }

      return _ScriptedConnection(next, state);
    }

    setUp(() {
      state = _SharedState();
      generation = 0;
    });

    Future<RedisBroker> broker() async {
      return RedisBroker(
        connection: ReconnectingRedisConnection(() async => open()),
        openConnection: () => ReconnectingRedisConnection(() async => open()),
        blockFor: const Duration(milliseconds: 10),
      );
    }

    test('a publish after the link dies reaches a fresh connection', () async {
      final b = await broker();

      await b.publish('orders', 'first');
      expect(state.commands.first, startsWith('gen1:XADD'));

      // The server goes away: generation 1's socket is dead.
      state.failLinkForGeneration.add(1);

      await b.publish('orders', 'second');

      // Retried on a new connection rather than thrown at the caller. Without
      // this a publish keeps failing while Redis is up and healthy.
      expect(
        state.commands.where((c) => c.startsWith('gen2:XADD')),
        isNotEmpty,
        reason: 'the retry should land on generation 2',
      );
    });

    test('a consumer recreates a group the restart lost', () async {
      final b = await broker();

      await b.subscribe('orders', group: 'billing', onMessage: (_) {});

      // subscribe creates it up front.
      expect(state.groupsCreated, contains('orders/billing'));

      // The restart wipes it while the connection stays healthy -- the shape
      // that is invisible without handling NOGROUP.
      state.groupsCreated.clear();

      await _until(
        () => state.groupsCreated.contains('orders/billing'),
        describe: 'the read loop recreates the lost group',
      );

      await b.close();
    });

    test(
      'an open that fails is not cached, so a later attempt can succeed',
      () async {
        // The window after a restart where the server refuses connections. A
        // rejected future cached under `_opened` would be replayed to every
        // later caller, so the consumer never recovers even once Redis is
        // back -- worse than not reconnecting at all, and the actual bug this
        // test was written for.
        final b = await broker();

        // Generation 1 is healthy first, so the failure below is a restart
        // rather than a broker that never worked.
        await b.publish('orders', 'first');
        expect(state.commands.first, startsWith('gen1:XADD'));

        // The restart: the live socket dies, and the server is not yet
        // accepting connections again.
        state
          ..failLinkForGeneration.add(1)
          ..refuseOpenForGeneration.add(2);

        await expectLater(
          b.publish('orders', 'second'),
          throwsA(isA<SocketException>()),
        );

        // Redis is back: the next attempt must open generation 3, not replay
        // generation 2's failure.
        await b.publish('orders', 'third');

        expect(
          state.commands.where((c) => c.startsWith('gen3:XADD')),
          isNotEmpty,
          reason: 'a third open should have been attempted and succeeded',
        );
      },
    );
  });
}

Future<void> _until(bool Function() condition, {String? describe}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      final detail = describe == null ? '' : ': $describe';
      fail('condition never became true$detail');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
