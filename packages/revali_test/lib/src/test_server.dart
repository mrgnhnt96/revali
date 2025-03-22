import 'dart:async';
import 'dart:io';

import 'package:revali_test/src/test_request.dart';
import 'package:revali_test/src/test_response.dart';

class TestServer extends Stream<HttpRequest> implements HttpServer {
  TestServer()
      : _controller = StreamController.broadcast(),
        _webSocketResponses = StreamController.broadcast();

  final StreamController<HttpRequest> _controller;
  final StreamController<List<int>> _webSocketResponses;
  Completer<TestResponse>? _response;

  Future<TestResponse> send({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, String> cookies = const {},
    Object? body,
  }) {
    headers ??= {};
    if (cookies.isNotEmpty) {
      headers[HttpHeaders.cookieHeader] =
          cookies.entries.map((e) => '${e.key}=${e.value};').join();
    }

    final request = TestRequest(
      method: method,
      path: path,
      headers: headers,
      body: body,
      onWebSocketMessage: _webSocketResponses.add,
      onResponse: (response) {
        _response?.complete(response);
      },
    );

    _response?.completeError('Did not get a response before next request');

    _response = Completer<TestResponse>();

    _controller.add(request);

    return _response!.future;
  }

  Stream<List<int>> connect({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, String> cookies = const {},
    Stream<List<int>>? body,
    void Function()? onClose,
    void Function(HttpRequest)? onRequest,
  }) {
    headers ??= {};
    if (cookies.isNotEmpty) {
      headers[HttpHeaders.cookieHeader] =
          cookies.entries.map((e) => '${e.key}=${e.value};').join();
    }

    final request = TestRequest(
      method: method,
      path: path,
      headers: headers,
      body: body,
      onWebSocketMessage: _webSocketResponses.add,
      onResponse: (response) {
        _response?.complete(response);
        close(force: true);
        onClose?.call();
      },
    );

    onRequest?.call(request);

    _controller.add(request);

    return _webSocketResponses.stream;
  }

  @override
  Future<void> close({bool force = false}) async {
    await _controller.close();
    await _webSocketResponses.close();
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

  Stream<dynamic> get webSocketResponses => _webSocketResponses.stream;

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
