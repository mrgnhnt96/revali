import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('typed-path-params', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();

      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('int', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/typed-path/int/5',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 5});
    });

    test('malformed int is a 400', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/typed-path/int/five',
      );

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('double', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/typed-path/double/1.5',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 1.5});
    });

    test('num', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/typed-path/num/7',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 7});
    });

    test('bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/typed-path/bool/true',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': true});
    });
  });
}
