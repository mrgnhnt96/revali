@Tags(['integration'])
library;

import 'dart:async';
import 'dart:io';

import 'package:revali_redis/revali_redis.dart';
import 'package:test/test.dart';

/// Recovery from the Redis **server** going away and coming back.
///
/// `redis_integration_test.dart` has "a consumer group survives a restart of
/// the subscriber" — that restarts the *client*. Nothing restarted the server,
/// which is a different failure and the one that actually happened:
///
///   Unhandled exception:
///   SocketException: Connection reset by peer   → exit 255
///
/// `SocketRedisConnection` wrote to a dead socket, and nothing observed the
/// socket's `done` future, so the write error escaped as an unhandled async
/// error and took the process down. Behind that sat two more failures — the
/// link was never reopened, and a group lost with the server was never
/// recreated, so every later `XREADGROUP` answered `NOGROUP` while the
/// connection looked perfectly healthy.
///
/// That was found by restarting a real server by hand. This is that repro,
/// kept: a hand-run check protects nothing once the person who ran it moves on.
///
/// Unlike the rest of the suite, this starts its **own** `redis-server` on a
/// free port, because it has to kill it. It never touches a server you are
/// already running.

/// Where `redis-server` and `redis-cli` are, if they are anywhere.
final _redisServer = _which('redis-server');
final _redisCli = _which('redis-cli');

String? _which(String binary) {
  try {
    final result = Process.runSync('which', [binary]);
    if (result.exitCode != 0) return null;
    final path = '${result.stdout}'.trim();

    return path.isEmpty ? null : path;
  } catch (_) {
    return null;
  }
}

/// A `redis-server` this test owns and may kill.
class _OwnedRedis {
  _OwnedRedis(this.port, this._dir);

  final int port;
  final Directory _dir;

  static Future<int> freePort() async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();

    return port;
  }

  static Future<_OwnedRedis> start() async {
    final dir = await Directory.systemTemp.createTemp('revali_redis_restart');
    final server = _OwnedRedis(await freePort(), dir);
    await server.up();

    return server;
  }

  /// Boots the server and waits until it actually answers.
  ///
  /// `--save ''` and `--appendonly no` mean nothing is persisted, so a restart
  /// loses the stream and the consumer group — which is the whole point: a
  /// server that came back with its groups intact would not exercise the
  /// `NOGROUP` path at all.
  Future<void> up() async {
    final result = await Process.run(_redisServer!, [
      '--port',
      '$port',
      '--save',
      '',
      '--appendonly',
      'no',
      '--daemonize',
      'yes',
      '--dir',
      _dir.path,
      '--logfile',
      '${_dir.path}/redis.log',
    ]);

    if (result.exitCode != 0) {
      throw StateError('could not start redis-server: ${result.stderr}');
    }

    await _waitUntil(reachable, 'redis-server on $port to accept connections');
  }

  Future<void> down() async {
    await Process.run(_redisCli!, ['-p', '$port', 'shutdown', 'nosave']);
    await _waitUntil(
      () async => !await reachable(),
      'redis-server on $port to stop',
    );
  }

  Future<bool> reachable() async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 300),
      );
      socket.destroy();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await down();
    } catch (_) {
      // Already gone.
    }
    try {
      _dir.deleteSync(recursive: true);
    } catch (_) {
      // Best effort.
    }
  }
}

Future<void> _waitUntil(
  Future<bool> Function() condition,
  String describe, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  fail('timed out waiting for $describe');
}

Future<void> _waitFor(
  bool Function() condition,
  String describe, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  fail('timed out waiting for $describe');
}

void main() {
  /// Skips rather than fails when there is no `redis-server` to own.
  ///
  /// Checked inside the test body, not left to `dart_test.yaml`: the tag
  /// config is honoured by `dart test` but not by every runner, and a suite
  /// that fails on a machine without Redis is one people learn to ignore.
  bool hasRedis() {
    if (_redisServer == null || _redisCli == null) {
      markTestSkipped('redis-server / redis-cli not on PATH');

      return false;
    }

    return true;
  }

  test(
    'a consumer keeps working across a full server restart',
    () async {
      if (!hasRedis()) return;

      final server = await _OwnedRedis.start();
      addTearDown(server.dispose);

      final topic = 'restart-${DateTime.now().microsecondsSinceEpoch}';
      final seen = <String>[];

      final broker = await RedisBroker.connect(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        consumerName: 'restart-test',
      );
      addTearDown(() async {
        try {
          await broker.close();
        } catch (_) {
          // The server may already be gone.
        }
      });

      await broker.subscribe(
        topic,
        group: 'restart-group',
        onMessage: (message) => seen.add(message.payload),
      );

      // Prove the happy path first, so a later failure cannot be blamed on
      // setup that never worked.
      await broker.publish(topic, 'before-restart');
      await _waitFor(
        () => seen.contains('before-restart'),
        'the first message to arrive',
      );

      // The event under test. Nothing is persisted, so the stream and the
      // consumer group are both gone when it comes back.
      await server.down();
      await server.up();

      // Reaching here at all is half the assertion: before the fix, the write
      // to the dead socket escaped as an unhandled async error, which fails
      // the test rather than merely returning something wrong.
      await broker.publish(topic, 'after-restart');

      await _waitFor(
        () => seen.contains('after-restart'),
        'a message published after the restart to be delivered — the consumer '
        'must have reconnected AND recreated the group it lost',
      );

      expect(seen, containsAll(<String>['before-restart', 'after-restart']));
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'a publish still succeeds after the server it used has restarted',
    () async {
      if (!hasRedis()) return;

      final server = await _OwnedRedis.start();
      addTearDown(server.dispose);

      final topic = 'restart-pub-${DateTime.now().microsecondsSinceEpoch}';

      final broker = await RedisBroker.connect(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        consumerName: 'restart-pub-test',
      );
      addTearDown(() async {
        try {
          await broker.close();
        } catch (_) {}
      });

      await broker.publish(topic, 'first');

      await server.down();
      await server.up();

      // The control connection is separate from any subscription's, and dies
      // in the same instant. A publisher-only service has no read loop to
      // notice, so this is the path that has to recover on its own.
      await broker.publish(topic, 'second');

      // Read it back through a fresh consumer rather than trusting the write:
      // XADD returning without throwing is not proof the entry landed.
      final seen = <String>[];
      await broker.subscribe(
        topic,
        group: 'reader',
        onMessage: (message) => seen.add(message.payload),
      );
      await broker.publish(topic, 'third');

      await _waitFor(
        () => seen.contains('third'),
        'the stream to be readable after the restart',
      );
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );
}
