import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('header', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/user',
        headers: {
          'content-type': 'text/plain',
          'data': 'banana',
        },
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'banana'});
    });

    test('list-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/list-user',
        headers: {
          'content-type': 'application/json',
          'data': 'banana,apple',
        },
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': ['banana', 'apple'],
      });
    });

    test('optional-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/optional-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': null});
    });

    test('default-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/default-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'default'});
    });

    test('default-optional-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/default-optional-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'default'});
    });
  });
}
