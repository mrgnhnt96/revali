import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('query', () {
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
        path: '/api/query/user?data=banana',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'banana'});
    });

    test('list-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/list-user?data=banana&data=apple',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': ['banana', 'apple'],
      });
    });

    test('optional-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/optional-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': null});
    });

    test('default-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/default-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'default'});
    });

    test('default-optional-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/default-optional-user',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'default'});
    });
  });
}
