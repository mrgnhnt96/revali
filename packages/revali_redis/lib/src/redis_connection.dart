import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:revali_redis/src/resp.dart';

/// A command channel to Redis.
///
/// Abstracted so the broker can be tested without a server, and so a caller
/// can supply their own transport.
abstract interface class RedisConnection {
  /// Sends a command and returns its reply.
  Future<Object?> send(List<String> command);

  Future<void> close();
}

/// A [RedisConnection] over a TCP socket.
///
/// Deliberately small: Redis replies to commands in order, so a queue of
/// pending completers is all the bookkeeping a single connection needs.
class SocketRedisConnection implements RedisConnection {
  SocketRedisConnection._(this._socket) {
    _subscription = _socket.listen(
      _onData,
      onError: _failAll,
      onDone: () {
        _broken = true;
        _failAll(const SocketException('Redis closed the connection'));
      },
    );

    // A socket's *write* errors do not arrive on the read stream: they surface
    // on `done`. When Redis restarts, the next write lands on a dead socket
    // and, with nothing observing this future, the failure escapes as an
    // unhandled async error and takes the process down. Observed as
    // "SocketException: Connection reset by peer" killing a running consumer.
    _socket.done.then<void>(
      (_) => _broken = true,
      onError: (Object error, StackTrace stackTrace) {
        _broken = true;
        _failAll(error, stackTrace);
      },
    );
  }

  /// Opens a connection to [host]:[port].
  static Future<SocketRedisConnection> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);

    return SocketRedisConnection._(socket);
  }

  final Socket _socket;
  late final StreamSubscription<Uint8List> _subscription;

  final _pending = Queue<Completer<Object?>>();

  var _buffer = Uint8List(0);
  var _closed = false;
  var _broken = false;

  /// Whether this connection is unusable and should be replaced.
  ///
  /// Distinct from [_closed]: closed means we ended it, broken means the peer
  /// or the network did. A caller that can reconnect needs to tell those
  /// apart — reopening a connection the application deliberately closed would
  /// resurrect a shut-down broker.
  bool get isBroken => _broken;

  @override
  Future<Object?> send(List<String> command) {
    if (_closed) {
      return Future.error(const SocketException('Connection is closed'));
    }

    if (_broken) {
      return Future.error(
        const SocketException('Connection to Redis was lost'),
      );
    }

    final completer = Completer<Object?>();
    _pending.add(completer);

    try {
      _socket.add(encodeCommand(command));
    } catch (e, st) {
      // Writing to a dead socket throws synchronously on some platforms and
      // asynchronously on others. Either way the command has no chance of a
      // reply, so it fails here rather than waiting out a completer nothing
      // will ever complete.
      _broken = true;
      _failAll(e, st);
    }

    return completer.future;
  }

  void _onData(Uint8List chunk) {
    // Appended rather than decoded directly: a reply can arrive split across
    // packets, and a large XREADGROUP batch routinely does.
    _buffer = Uint8List.fromList([..._buffer, ...chunk]);

    while (_buffer.isNotEmpty && _pending.isNotEmpty) {
      final RespValue? reply;
      try {
        reply = decode(_buffer);
      } catch (e) {
        // An error reply belongs to the command that caused it; the rest of
        // the pipeline is still valid.
        _consumeErroredReply();
        _pending.removeFirst().completeError(e);
        continue;
      }

      if (reply == null) {
        // Incomplete: wait for more bytes.
        return;
      }

      _buffer = Uint8List.sublistView(_buffer, reply.length);
      _pending.removeFirst().complete(reply.value);
    }
  }

  /// Drops the error line that [decode] threw on, so the buffer stays aligned.
  void _consumeErroredReply() {
    for (var i = 0; i + 1 < _buffer.length; i++) {
      if (_buffer[i] == 0x0d && _buffer[i + 1] == 0x0a) {
        _buffer = Uint8List.sublistView(_buffer, i + 2);

        return;
      }
    }

    _buffer = Uint8List(0);
  }

  void _failAll(Object error, [StackTrace? stackTrace]) {
    while (_pending.isNotEmpty) {
      _pending.removeFirst().completeError(error, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;

    await _subscription.cancel();
    _socket.destroy();

    _failAll(const SocketException('Connection closed'));
  }
}

/// Opens a connection on first use and replaces it when the peer goes away.
///
/// Reconnection is not an optimisation here. A Redis restart kills every
/// socket at once; without this the broker holds a dead one forever, so a
/// consumer stops receiving and a publish throws, while the server it needs
/// is up and healthy again.
///
/// Recreating the consumer group is deliberately *not* done here. A restart
/// that lost the group leaves the socket perfectly healthy, so the failure
/// surfaces as a `NOGROUP` reply on the next read rather than as a broken
/// link — and it is handled where the topic and group are known, in the
/// subscription's read loop.
class ReconnectingRedisConnection implements RedisConnection {
  ReconnectingRedisConnection(this._open, {RedisConnection? initial})
    : _opened = initial == null ? null : Future.value(initial);

  final Future<RedisConnection> Function() _open;

  Future<RedisConnection>? _opened;
  var _closed = false;

  /// The current connection, opening one if there is none.
  ///
  /// The cache is cleared when opening *fails*. Holding the rejected future
  /// instead would be permanent: a restart leaves a window of a second or two
  /// where the server refuses connections, and a single attempt landing in it
  /// would be replayed to every later caller, so the consumer never recovers
  /// even though Redis is back. That is exactly the failure this class exists
  /// to prevent, and caching made it worse than not reconnecting at all.
  Future<RedisConnection> get _connection async {
    if (_opened case final existing?) {
      return existing;
    }

    final opening = _open();
    _opened = opening;

    try {
      return await opening;
    } catch (_) {
      if (identical(_opened, opening)) {
        _opened = null;
      }

      rethrow;
    }
  }

  @override
  Future<Object?> send(List<String> command) async {
    if (_closed) {
      throw const SocketException('Connection is closed');
    }

    final connection = await _connection;

    try {
      return await connection.send(command);
    } on RedisError {
      // A protocol-level error is the server answering, not the link failing.
      // Reconnecting would hide a real reply -- including NOGROUP, which the
      // caller must see in order to recreate the group.
      rethrow;
    } catch (_) {
      if (_closed) rethrow;

      // Anything else means the link is gone. One reconnect and one retry: if
      // the second attempt fails too, the error is the caller's to handle,
      // and the read loop already backs off before trying again.
      return _reconnectAndRetry(connection, command);
    }
  }

  Future<Object?> _reconnectAndRetry(
    RedisConnection dead,
    List<String> command,
  ) async {
    try {
      await dead.close();
    } catch (_) {
      // Already gone; closing is best-effort.
    }

    _opened = null;

    final fresh = await _connection;

    return fresh.send(command);
  }

  @override
  Future<void> close() async {
    _closed = true;

    if (_opened case final opened?) {
      await (await opened).close();
    }
  }
}
