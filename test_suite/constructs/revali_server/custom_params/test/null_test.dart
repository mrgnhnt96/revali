import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('path-params', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    group('with body', () {
      test('root', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/null/root',
          headers: {'content-type': 'application/json'},
          body: {'name': 'John'},
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, {
          'data': {'name': 'John'},
        });
      });

      test('nested', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/null/nested',
          headers: {'content-type': 'application/json'},
          body: {
            'data': {'name': 'John'},
          },
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, {
          'data': {'name': 'John'},
        });
      });

      test('multiple', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/null/multiple',
          headers: {'content-type': 'application/json'},
          body: {
            'one': {'name': 'John'},
            'two': {'name': 'Jane'},
          },
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, {
          'data': [
            {'name': 'John'},
            {'name': 'Jane'},
          ],
        });
      });
    });

    group('with null body', () {
      test('root', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/null/root',
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, {'data': null});
      });

      test('nested', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/null/nested',
          headers: {'content-type': 'application/json'},
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, {'data': null});
      });

      test('multiple', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/null/multiple',
          headers: {'content-type': 'application/json'},
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(response.body, {
          'data': [null, null],
        });
      });
    });
  });
}
