import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('query-params', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();

      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('required should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/required?shopId=abc',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'abc'});
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
        path: '/api/query/all?shopId=abc&shopId=def',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'abc,def'});
    });

    test('all should return error when not provided', () async {
      final response = await server.send(method: 'GET', path: '/api/query/all');

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

    test('String query stringifies coerced numeric values', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/coerced-string?shopId=5',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '5'});
    });

    test('String query stringifies coerced bool values', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/coerced-string?shopId=true',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'true'});
    });

    test('String query preserves leading zeros', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/coerced-string?shopId=007',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '007'});
    });

    test('double query promotes coerced int values', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/coerced-double?n=5',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '5.0'});
    });
  });
}
