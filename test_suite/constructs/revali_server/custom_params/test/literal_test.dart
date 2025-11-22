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

    test('root', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/root',
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
        path: '/api/literal/nested',
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
        path: '/api/literal/multiple',
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
}
