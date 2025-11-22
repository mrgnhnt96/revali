import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('stream', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('data-string', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/data-string',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('string', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/string',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, ['', '']);
    });

    test('bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/bool',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('int', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/int',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('double', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/double',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/record',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('named-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/named-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('partial-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/partial-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('list-of-records', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/list-of-records',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('list-of-strings', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/list-of-strings',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('list-of-maps', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/list-of-maps',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('map-string-dynamic', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/map-string-dynamic',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('map-dynamic-dynamic', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/map-dynamic-dynamic',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('map-dynamic-dynamic-with-null', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/map-dynamic-dynamic-with-null',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {
          'data': {'foo': null},
        },
        {
          'data': {'bar': null},
        },
      ]);
    });

    test('set', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/set',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('iterable', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/iterable',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, [
        {'data': null},
        {'data': null},
      ]);
    });

    test('bytes', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/bytes',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, ['', '']);
    });
  });
}
