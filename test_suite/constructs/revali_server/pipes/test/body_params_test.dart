import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('body', () {
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
        path: '/api/body/user',
        headers: {
          'content-type': 'text/plain',
        },
        body: 'banana',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'banana'});
    });

    test('list-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/list-user',
        headers: {
          'content-type': 'application/json',
        },
        body: ['banana', 'apple'],
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': ['banana', 'apple'],
      });
    });

    test('optional-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/optional-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': null});
    });

    test('default-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/default-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'default'});
    });

    test('default-optional-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/default-optional-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'default'});
    });
  });
}
