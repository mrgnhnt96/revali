import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('custom-types', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('returns user successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('returns future user successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('returns stream user successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/stream-user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'name': 'Hello world!'});
    });

    test('returns list of users successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/list-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {'name': 'Hello world!'},
      ]);
    });

    test('returns future list of users successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-list-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {'name': 'Hello world!'},
      ]);
    });

    test('returns map of users successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/map-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'user': {'name': 'Hello world!'},
        },
      });
    });

    test('returns future map of users successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-map-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'user': {'name': 'Hello world!'},
        },
      });
    });

    test('returns record of users successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/record-of-users',
      );

      expect(response.statusCode, 500);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, null);
    });

    test('returns future record of users successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-record-of-users',
      );

      expect(response.statusCode, 500);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, null);
    });
  });
}
