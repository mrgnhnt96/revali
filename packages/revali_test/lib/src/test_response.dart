import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:revali_test/revali_test.dart';
import 'package:revali_test/src/test_http_connection_info.dart';

class TestResponse implements HttpResponse {
  TestResponse({
    required this.onClose,
    this.webSocketInput,
    this.onWebSocketMessage,
    this.connectionInfo = const TestHttpConnectionInfo(),
  });

  final void Function(TestResponse response) onClose;
  final Stream<Uint8List>? webSocketInput;
  final void Function(List<int>)? onWebSocketMessage;

  @override
  bool bufferOutput = false;

  @override
  int get contentLength => _headers.contentLength;
  @override
  set contentLength(int value) => _headers.contentLength = value;

  @override
  Duration? deadline;

  @override
  Encoding encoding = utf8;

  @override
  bool persistentConnection = false;

  @override
  String reasonPhrase = '';

  @override
  int statusCode = -1;

  List<List<int>>? _body;

  dynamic get body => switch (_body) {
        null => null,
        [final data] => _decode(data),
        final data => [
            for (final item in data) _decode(item),
          ],
      };

  dynamic _decode(List<int> data) {
    final decoded = encoding.decode(data);
    try {
      return jsonDecode(decoded);
    } catch (_) {}

    return decoded;
  }

  @override
  void add(List<int> data) {
    (_body ??= []).add(data);
  }

  @override
  Never addError(Object error, [StackTrace? stackTrace]) {
    throw UnimplementedError();
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> close() async {
    onClose(this);
  }

  @override
  Never get cookies => throw UnimplementedError();

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) async {
    return TestSocket(
      input: webSocketInput,
      onWebSocketMessage: onWebSocketMessage,
      onClose: () {
        onClose(this);
      },
    );
  }

  @override
  Never get done => throw UnimplementedError();

  @override
  Future<void> flush() async {}

  @override
  TestHeaders get headers => _headers;
  final _headers = TestHeaders({});

  @override
  Never redirect(
    Uri location, {
    int status = HttpStatus.movedTemporarily,
  }) {
    throw UnimplementedError();
  }

  @override
  Never write(Object? object) {
    throw UnimplementedError('write');
  }

  @override
  Never writeAll(Iterable<Object?> objects, [String separator = '']) {
    throw UnimplementedError('writeAll');
  }

  @override
  Never writeCharCode(int charCode) {
    throw UnimplementedError('writeCharCode');
  }

  @override
  Never writeln([Object? object = '']) {
    throw UnimplementedError('writeln');
  }

  @override
  final HttpConnectionInfo? connectionInfo;
}
