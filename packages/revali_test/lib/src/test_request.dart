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
    required this.onWebSocketMessage,
    Map<String, List<String>> headers = const {},
    Object? body,
  }) : _headers = headers {
    if (body is Stream) {
      _webSocketInput = switch (body) {
        Stream<Uint8List>() => body,
        Stream<List<int>>() => body.map(Uint8List.fromList),
        _ => throw Exception(
            'Invalid body type, expected Stream<List<int>>, got $body',
          ),
      };

      _body = null;
    } else {
      _body = body;
      _webSocketInput = null;
    }
  }

  @override
  final String method;
  final String path;
  final Map<String, List<String>> _headers;
  late final Object? _body;
  late final Stream<Uint8List>? _webSocketInput;
  final void Function(TestResponse response) onResponse;
  final void Function(List<int>)? onWebSocketMessage;

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
