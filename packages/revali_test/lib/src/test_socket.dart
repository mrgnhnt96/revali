import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class TestSocket extends Stream<Uint8List> implements Socket {
  TestSocket({
    this.onWebSocketMessage,
    Stream<Uint8List>? input,
    this.onClose,
  }) : _input = input;

  final void Function(List<int>)? onWebSocketMessage;
  final Stream<Uint8List>? _input;
  final void Function()? onClose;

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {
    onWebSocketMessage?.call(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw UnimplementedError('addError');
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      // check if data is close frame
      if (data.length == 2) {
        if (data case [0x88, _]) {
          await close();
          break;
        }

        continue;
      }

      add(data);
    }
  }

  @override
  InternetAddress get address => InternetAddress('0.0.0.0');

  @override
  Future<void> close() async {
    onClose?.call();
  }

  @override
  void destroy() {
    throw UnimplementedError('destroy');
  }

  @override
  Future<void> get done async {}

  @override
  Future<void> flush() async {}

  @override
  Never getRawOption(RawSocketOption option) {
    throw UnimplementedError('getRawOption');
  }

  @override
  int get port => 8080;

  @override
  InternetAddress get remoteAddress => InternetAddress('0.0.0.0');

  @override
  int get remotePort => 8080;

  @override
  bool setOption(SocketOption option, bool enabled) {
    throw UnimplementedError('setOption');
  }

  @override
  void setRawOption(RawSocketOption option) {
    throw UnimplementedError('setRawOption');
  }

  @override
  void write(Object? object) {
    throw UnimplementedError('write');
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    throw UnimplementedError('writeAll');
  }

  @override
  void writeCharCode(int charCode) {
    throw UnimplementedError('writeCharCode');
  }

  @override
  void writeln([Object? object = '']) {
    throw UnimplementedError('writeln');
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final input = _input ?? const Stream.empty();

    return input.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
