import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('header-params', () {
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
        path: '/api/header/required',
        headers: {'X-Shop-Id': '123'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('required should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/required',
      );

      expect(response.statusCode, 500);
      expect(
        response.body,
        startsWith('''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: X-Shop-Id, location: @header

Stack Trace:
.revali/server/routes/__header_route.dart'''),
      );
    });

    test('optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/optional',
        headers: {'X-Shop-Id': '123'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('all should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all',
        headers: {'X-Shop-Id': '123,456'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });

    test('all should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all',
      );

      expect(response.statusCode, 500);
      expect(
        response.body,
        startsWith('''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: X-Shop-Id, location: @header (all)

Stack Trace:
.revali/server/routes/__header_route.dart'''),
      );
    });

    test('all-optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all-optional',
        headers: {'X-Shop-Id': '123,456'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });
  });
}
