import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:revali_test/src/test_headers.dart';
import 'package:revali_test/src/test_http_connection_info.dart';
import 'package:revali_test/src/test_response.dart';

class TestRequest extends Stream<Uint8List> implements HttpRequest {
  TestRequest({
    required this.method,
    required this.path,
    required this.onResponse,
    required this.onWebSocketMessage,
    Map<String, String> headers = const {},
    Object? body,
    Stream<List<int>>? webSocketInput,
    this.connectionInfo = const TestHttpConnectionInfo(),
  }) : _headers = headers,
       _body = body {
    // WebSocket input arrives through its own parameter. It used to be
    // inferred from `body` being a Stream, which made a *streamed HTTP body*
    // impossible to express -- it was silently read as socket frames and the
    // request arrived empty.
    _webSocketInput = switch (webSocketInput) {
      null => null,
      Stream<Uint8List>() => webSocketInput,
      _ => webSocketInput.map(Uint8List.fromList),
    };
  }

  @override
  final String method;
  final String path;
  final Map<String, String> _headers;
  late final Object? _body;
  late final Stream<Uint8List>? _webSocketInput;
  final void Function(TestResponse response) onResponse;
  final void Function(List<int>)? onWebSocketMessage;
  @override
  final HttpConnectionInfo? connectionInfo;

  @override
  X509Certificate? get certificate => throw UnimplementedError();

  @override
  int get contentLength => -1;

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
    // Bytes and streams pass through untouched. JSON-encoding them -- which
    // is what happened when this only special-cased String -- turned a
    // binary upload into the *text* "[1,2,3]".
    final source = switch (_body) {
      null => const Stream<List<int>>.empty(),
      final Stream<List<int>> stream => stream,
      final List<int> bytes => Stream.value(bytes),
      final String text => Stream.value(utf8.encode(text)),
      final other => Stream.value(utf8.encode(jsonEncode(other))),
    };

    return source
        .map(Uint8List.fromList)
        .listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  @override
  bool get persistentConnection => throw UnimplementedError();

  @override
  String get protocolVersion => 'HTTP/1.1';

  @override
  Uri get requestedUri => uri;

  @override
  HttpResponse get response => TestResponse(
    onClose: onResponse,
    webSocketInput: _webSocketInput,
    onWebSocketMessage: onWebSocketMessage,
  );

  @override
  HttpSession get session => throw UnimplementedError();

  @override
  Uri get uri => Uri.parse(path);
}
