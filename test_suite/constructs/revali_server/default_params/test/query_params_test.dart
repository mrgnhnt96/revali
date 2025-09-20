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

    test('required should return success when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/required',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('all should return success when not provided', () async {
      final response = await server.send(method: 'GET', path: '/api/query/all');

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });

    test('all-optional should return success when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/query/all-optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });
  });
}
