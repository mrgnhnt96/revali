import 'dart:convert';
import 'dart:io';

import 'package:revali_test/src/test_headers.dart';

class TestResponse implements HttpResponse {
  TestResponse({
    required this.onClose,
  });

  final void Function(TestResponse response) onClose;

  @override
  bool bufferOutput = false;

  @override
  int contentLength = -1;

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

  final List<List<int>> _body = [];

  dynamic get json => switch (_body) {
        [final data] => _decode(data),
        final data => [
            for (final item in data) _decode(item),
          ],
      };

  dynamic _decode(List<int> data) {
    final decoded = utf8.decode(data);
    try {
      return jsonDecode(decoded);
    } catch (_) {}

    return decoded;
  }

  @override
  void add(List<int> data) {
    _body.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
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
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();

  @override
  List<Cookie> get cookies => [];

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) {
    throw UnimplementedError();
  }

  @override
  Future<void> get done => throw UnimplementedError();

  @override
  Future<void> flush() async {}

  @override
  HttpHeaders get headers => TestHeaders({});

  @override
  Future<void> redirect(
    Uri location, {
    int status = HttpStatus.movedTemporarily,
  }) {
    throw UnimplementedError();
  }

  @override
  void write(Object? object) {
    throw UnimplementedError('write');
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
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
}
