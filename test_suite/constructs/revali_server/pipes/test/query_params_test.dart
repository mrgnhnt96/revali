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

    test('bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/bool?data=true',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': true});
    });

    test('list-bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/list-bool?data=true&data=false',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': [true, false],
      });
    });

    test('optional-bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/optional-bool',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': true});
    });

    test('default-bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/default-bool',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': true});
    });

    test('default-optional-bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/default-optional-bool',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': true});
    });
  });
}
