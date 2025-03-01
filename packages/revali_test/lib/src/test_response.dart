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
    final decoded = utf8.decode(data);
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
  Never get connectionInfo => throw UnimplementedError();

  @override
  Never get cookies => throw UnimplementedError();

  @override
  Never detachSocket({bool writeHeaders = true}) {
    throw UnimplementedError();
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
}
