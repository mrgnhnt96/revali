import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('path-params', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('shop id', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/shop/123',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('product id', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/shop/123/product/456',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': '456',
      });
    });

    test('variant id', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/shop/123/product/456/variant/789',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': {
          'shopId': '123',
          'productId': '456',
          'variantId': '789',
        },
      });
    });
  });
}
