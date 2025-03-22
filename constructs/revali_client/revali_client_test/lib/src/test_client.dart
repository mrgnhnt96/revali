import 'dart:async';
import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_test/revali_test.dart';

final class TestClient implements HttpClient {
  TestClient(this.server, [this.onRequest, this.onResponse]) : sse = false;
  TestClient.sse(this.server, [this.onRequest, this.onResponse]) : sse = true;

  final bool sse;

  final TestServer server;
  final void Function(HttpRequest)? onRequest;
  final void Function(HttpResponse)? onResponse;

  HttpResponse? _response;
  HttpResponse? get response => _response;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    return switch (sse) {
      true => _connect(request),
      false => _send(request),
    };
  }

  Future<HttpResponse> _send(HttpRequest request) async {
    onRequest?.call(request);

    final response = await server.send(
      method: request.method,
      path: request.url.path,
      headers: request.headers,
      body: request.body,
    );

    final stream = switch (response.body) {
      null => const Stream<List<int>>.empty(),
      final String e => Stream.value(utf8.encode(e)),
      final List<dynamic> e => Stream.fromIterable(
          e.map((e) {
            if (e is String) {
              return utf8.encode(e);
            }

            return utf8.encode(jsonEncode(e));
          }),
        ),
      _ => Stream.value(utf8.encode(jsonEncode(response.body))),
    };

    final httpResponse = HttpResponse(
      stream: stream,
      statusCode: response.statusCode,
      headers: response.headers.values,
      contentLength: switch (response.contentLength) {
        -1 => null,
        final int length => length,
      },
      request: request,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );

    onResponse?.call(httpResponse);

    return httpResponse;
  }

  Future<HttpResponse> _connect(HttpRequest request) async {
    onRequest?.call(request);

    final body = StreamController<List<int>>.broadcast();

    final response = HttpResponse(
      stream: body.stream,
      request: request,
      statusCode: -1,
      headers: const {},
      contentLength: null,
      persistentConnection: false,
      reasonPhrase: null,
    );

    _response = response;

    final canSend = Completer<void>();

    server
        .connect(
      method: request.method,
      path: request.url.path,
      headers: request.headers,
      body: Stream.value(utf8.encode(request.body)),
      onResponse: (resp) async {
        resp.headers.forEach((key, values) {
          response.headers[key] = values.join(', ');
        });
        response
          ..statusCode = resp.statusCode
          ..contentLength = resp.contentLength
          ..persistentConnection = resp.persistentConnection
          ..reasonPhrase = resp.reasonPhrase;

        onResponse?.call(response);
      },
    )
        .asyncMap((e) async {
      await canSend.future;

      return e;
    }).listen(
      body.add,
      onDone: body.close,
      onError: body.addError,
      cancelOnError: true,
    );

    await Future<void>.delayed(Duration.zero);

    canSend.complete();

    return response;
  }
}
