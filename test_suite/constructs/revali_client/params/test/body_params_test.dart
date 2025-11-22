import 'package:revali_client/revali_client.dart';
import 'package:revali_client_params/revali_client_params.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('body params', () {
    late TestServer server;
    late Server client;
    HttpRequest? request;

    setUp(() {
      server = TestServer();

      client = Server(client: TestClient(server, (req) => request = req));

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

    test('root', () async {
      final response = await client.bodyParams.root(data: 'Hello world!');

      expect(response, 'Hello world!');
      verifyRequest('/api/body/root', method: 'GET');
      expect(request?.body, 'Hello world!');
    });

    test('nested', () async {
      final response = await client.bodyParams.nested(data: 'Hello world!');

      expect(response, 'Hello world!');
      verifyRequest('/api/body/nested', method: 'GET');
      expect(request?.body, '{"data":"Hello world!"}');
    });

    test('multiple', () async {
      final response = await client.bodyParams.multiple(name: 'John', age: 30);

      expect(response, 'John 30');
      verifyRequest('/api/body/multiple', method: 'GET');
      expect(request?.body, '{"name":"John","age":30}');
    });
  });
}
