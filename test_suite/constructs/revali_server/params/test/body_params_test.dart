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

    test('root', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/root',
        headers: {
          'content-type': 'text/plain',
        },
        body: '123',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('nested', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/nested',
        headers: {
          'content-type': 'application/json',
        },
        body: {'data': '456'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {
        'data': '456',
      });
    });

    test('multiple', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/multiple',
        headers: {
          'content-type': 'application/json',
        },
        body: {'name': 'John', 'age': 30},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'John 30'});
    });

    test('dynamic (int)', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/dynamic',
        headers: {
          'content-type': 'application/json',
        },
        body: {'data': 123},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('dynamic (string)', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/body/dynamic',
        headers: {
          'content-type': 'application/json',
        },
        body: {'data': 'Hello world!'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'Hello world!'});
    });
  });
}
