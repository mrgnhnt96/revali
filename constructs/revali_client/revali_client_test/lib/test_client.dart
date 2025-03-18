import 'dart:convert';

import 'package:http/http.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_test/revali_test.dart';

final class TestClient implements HttpClient {
  TestClient(this.server, this.onRequest);

  final TestServer server;
  final void Function(Request) onRequest;

  @override
  Future<StreamedResponse> send(Request request) async {
    onRequest(request);

    final response = await server.send(
      method: request.method,
      path: request.url.path,
      headers: request.headers.map(
        (key, value) => MapEntry(key, value.split(',')),
      ),
      body: request.body,
    );

    final encoded = switch (response.body) {
      final String e => utf8.encode(e),
      _ => utf8.encode(jsonEncode(response.body)),
    };

    return StreamedResponse(
      Stream.value(encoded),
      response.statusCode,
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
