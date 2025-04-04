import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('body-params', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('non-null', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/non-null',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('nullable', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/nullable',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': '123',
      });
    });

    test('multiple-non-null', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/multiple-non-null',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'John 30'});
    });

    test('multiple-nullable', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/multiple-nullable',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'John 30'});
    });
  });
}
