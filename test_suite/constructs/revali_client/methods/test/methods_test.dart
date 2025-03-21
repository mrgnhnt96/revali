import 'package:revali_client/revali_client.dart';
import 'package:revali_client_methods/revali_client_methods.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('methods DELETE', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

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

    void verifyRequest(
      HttpRequest? request,
      String path, {
      required String method,
    }) {
      expect(request?.url.path, path);
      expect(request?.headers, isEmpty);
      expect(request?.body, isEmpty);
      expect(request?.method, method);
    }

    test('returns a successful response when DELETE request', () async {
      final response = await client.methods.delete();

      expect(response, 'Hello world!');
      verifyRequest(request, '/api/methods', method: 'DELETE');
    });

    test('returns a successful response when GET request', () async {
      final response = await client.methods.get();

      expect(response, 'Hello world!');
      verifyRequest(request, '/api/methods', method: 'GET');
    });

    test('returns a successful response when PATCH request', () async {
      final response = await client.methods.patch();

      expect(response, 'Hello world!');
      verifyRequest(request, '/api/methods', method: 'PATCH');
    });

    test('returns a successful response when POST request', () async {
      final response = await client.methods.post();

      expect(response, 'Hello world!');
      verifyRequest(request, '/api/methods', method: 'POST');
    });

    test('returns a successful response when PUT request', () async {
      final response = await client.methods.put();

      expect(response, 'Hello world!');
      verifyRequest(request, '/api/methods', method: 'PUT');
    });
  });
}
