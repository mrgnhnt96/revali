import 'dart:convert';

import 'package:revali_client/revali_client.dart';
import 'package:revali_test/revali_test.dart';

final class TestClient implements HttpClient {
  TestClient(this.server, [this.onRequest]);

  final TestServer server;
  final void Function(HttpRequest)? onRequest;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    onRequest?.call(request);

    final response = await server.send(
      method: request.method,
      path: request.url.path,
      headers: request.headers.map(
        (key, value) => MapEntry(key, value.split(',')),
      ),
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

    return HttpResponse(
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
  }
}
