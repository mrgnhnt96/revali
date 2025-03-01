import 'dart:async';
import 'dart:io';

import 'package:revali_test/src/test_request.dart';
import 'package:revali_test/src/test_response.dart';

class TestServer extends Stream<HttpRequest> implements HttpServer {
  TestServer() : _controller = StreamController<HttpRequest>.broadcast();

  final StreamController<HttpRequest> _controller;
  Completer<TestResponse>? _response;

  Future<TestResponse> send({
    required String method,
    required String path,
    Map<String, List<String>>? headers,
    Map<String, String> cookies = const {},
    Object? body,
  }) {
    headers ??= {};
    headers[HttpHeaders.cookieHeader] =
        cookies.entries.map((e) => '${e.key}=${e.value};').toList();

    final request = TestRequest(
      method: method,
      path: path,
      headers: headers,
      body: body,
      onResponse: (response) {
        _response?.complete(response);
      },
    );

    _response?.completeError('Did not get a response before next request');

    _response = Completer<TestResponse>();

    _controller.add(request);

    return _response!.future;
  }

  @override
  Future<void> close({bool force = false}) async {
    await _controller.close();
  }

  @override
  bool get autoCompress => throw UnimplementedError();

  @override
  Duration? get idleTimeout => throw UnimplementedError();

  @override
  String? get serverHeader => throw UnimplementedError();

  @override
  InternetAddress get address => InternetAddress('0.0.0.0');

  @override
  HttpConnectionsInfo connectionsInfo() {
    throw UnimplementedError();
  }

  @override
  HttpHeaders get defaultResponseHeaders => throw UnimplementedError();

  @override
  StreamSubscription<HttpRequest> listen(
    void Function(HttpRequest event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get port => 8080;

  @override
  // ignore: avoid_setters_without_getters
  set sessionTimeout(int timeout) {}

  @override
  set autoCompress(bool autoCompress) {
    throw UnimplementedError();
  }

  @override
  set idleTimeout(Duration? idleTimeout) {
    throw UnimplementedError();
  }

  @override
  set serverHeader(String? serverHeader) {
    throw UnimplementedError();
  }
}
