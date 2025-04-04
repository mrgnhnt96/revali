import 'package:revali_client/revali_client.dart';
import 'package:revali_client_default_params/revali_client_default_params.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('query params', () {
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

    void verifyRequest(String path, {required String method}) {
      final req = request;
      expect(req?.url.path, path);
      expect(req?.method, method);
    }

    test('required', () async {
      final response = await client.queryParams.required();

      expect(response, 'Hello world');
      verifyRequest('/api/query/required', method: 'GET');
      expect(request?.url.queryParametersAll['data'], isNull);
    });

    test('optional', () async {
      final response = await client.queryParams.optional();

      expect(response, 'Hello world');
      verifyRequest('/api/query/optional', method: 'GET');
      expect(request?.url.queryParametersAll['data'], isNull);
    });

    test('all', () async {
      final response = await client.queryParams.all();

      expect(response, [
        'Hello',
        'world',
      ]);
      verifyRequest('/api/query/all', method: 'GET');
      expect(request?.url.queryParametersAll['data'], isNull);
    });

    test('all-optional', () async {
      final response = await client.queryParams.allOptional();

      expect(response, [
        'Hello',
        'world',
      ]);
      verifyRequest('/api/query/all-optional', method: 'GET');
      expect(request?.url.queryParametersAll['data'], isNull);
    });
  });
}
