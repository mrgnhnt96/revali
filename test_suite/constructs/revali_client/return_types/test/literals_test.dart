import 'dart:async';
import 'dart:convert';

import 'package:client/client.dart';
import 'package:http/http.dart';
import 'package:revali_client/revali_client.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group(
    'literals',
    () {
      late TestServer server;
      late Server client;
      Request? request;

      setUp(() {
        server = TestServer();

        client = Server(
          client: TestClient(server, (req) => request = req),
        );

        createServer(server);
      });

      tearDown(() {
        server.close();
      });

      test('data-string', () async {
        final response = await client.literals.dataString();

        expect(response, isNotNull);
        expect(request, isNotNull);
      });
    },
    skip: true,
  );
}

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

    return StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(response.body))),
      response.statusCode,
      headers: response.headers.values,
      contentLength: response.contentLength,
      request: request,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
