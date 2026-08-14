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
      onDone: () =>
          _failAll(const SocketException('Redis closed the connection')),
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

  @override
  Future<Object?> send(List<String> command) {
    if (_closed) {
      return Future.error(const SocketException('Connection is closed'));
    }

    final completer = Completer<Object?>();
    _pending.add(completer);

    _socket.add(encodeCommand(command));

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
