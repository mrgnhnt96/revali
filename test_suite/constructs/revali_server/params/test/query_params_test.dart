import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('query-params', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('required should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/required?shopId=123',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('required should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/required',
      );

      expect(response.statusCode, 500);
      expect(
        response.body,
        startsWith('''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: shopId, location: @query

Stack Trace:
.revali/server/routes/__query_route.dart'''),
      );
    });

    test('optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'no shop id'});
    });

    test('all should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/all?shopId=123&shopId=456',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });

    test('all should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/all',
      );

      expect(response.statusCode, 500);
      expect(
        response.body,
        startsWith('''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: shopId, location: @query (all)

Stack Trace:
.revali/server/routes/__query_route.dart'''),
      );
    });

    test('all-optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/all-optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'no shop ids'});
    });
  });
}
