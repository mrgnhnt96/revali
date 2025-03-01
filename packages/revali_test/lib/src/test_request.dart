import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:revali_test/src/test_headers.dart';
import 'package:revali_test/src/test_response.dart';

class TestRequest extends Stream<Uint8List> implements HttpRequest {
  TestRequest({
    required this.method,
    required this.path,
    required this.onResponse,
    Map<String, List<String>> headers = const {},
    Object? body,
  })  : _headers = headers,
        _body = body;

  @override
  final String method;
  final String path;
  final Map<String, List<String>> _headers;
  final Object? _body;
  final void Function(TestResponse response) onResponse;

  @override
  X509Certificate? get certificate => throw UnimplementedError();

  @override
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();

  @override
  int get contentLength => throw UnimplementedError();

  @override
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  HttpHeaders get headers => TestHeaders(_headers);

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final body = switch (_body) {
      String() => _body,
      null => '',
      _ => jsonEncode(_body),
    };

    return Stream.fromIterable([utf8.encode(body)]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  @override
  bool get persistentConnection => throw UnimplementedError();

  @override
  String get protocolVersion => 'HTTP/1.1';

  @override
  Uri get requestedUri => uri;

  @override
  HttpResponse get response => TestResponse(
        onClose: onResponse,
      );

  @override
  HttpSession get session => throw UnimplementedError();

  @override
  Uri get uri => Uri.parse(path);
}
