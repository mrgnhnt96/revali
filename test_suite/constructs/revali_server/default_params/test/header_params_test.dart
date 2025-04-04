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

    test('required should return success when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/required',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('optional should return success when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('all should return success when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });

    test('all-optional should return success when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all-optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });
  });
}
