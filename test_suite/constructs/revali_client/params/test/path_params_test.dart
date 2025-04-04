import 'package:revali_client/revali_client.dart';
import 'package:revali_client_params/revali_client_params.dart';
import 'package:revali_client_test/revali_client_test.dart';
import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('path params', () {
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
      final response = await client.pathParams.fromController(shopId: '123');

      expect(response, '123');
      verifyRequest('/api/shop/123', method: 'GET');
    });

    test('optional', () async {
      final response = await client.pathParams.fromMethod(
        shopId: 'abc',
        productId: '123',
      );

      expect(response, '123');
      verifyRequest('/api/shop/abc/product/123', method: 'GET');
    });

    test('all', () async {
      final response = await client.pathParams.fromMethodWithMultipleParams(
        shopId: 'abc',
        productId: '123',
        variantId: '456',
      );

      expect(response, {
        'shopId': 'abc',
        'productId': '123',
        'variantId': '456',
      });
      verifyRequest('/api/shop/abc/product/123/variant/456', method: 'GET');
    });
  });
}
