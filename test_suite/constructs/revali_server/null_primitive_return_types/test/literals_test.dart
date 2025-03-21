import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literals', () {
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
        path: '/api/literals/data-string',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': null});
    });

    test('string', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/string',
      );

      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, null);
    });

    test('bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/bool',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': null});
    });

    test('int', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/int',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': null});
    });

    test('double', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/double',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': null});
    });

    test('record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/record',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': null,
      });
    });

    test('named-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/named-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': null,
      });
    });

    test('partial-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/partial-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': null,
      });
    });

    test('list-of-records', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/list-of-records',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('list-of-strings', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/list-of-strings',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('list-of-maps', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/list-of-maps',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('map-string-dynamic', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/map-string-dynamic',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('map-dynamic-dynamic', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/map-dynamic-dynamic',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('map-dynamic-dynamic-with-null', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/map-dynamic-dynamic-with-null',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': {'foo': null},
      });
    });

    test('set', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/set',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('iterable', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/iterable',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': null,
      });
    });

    test('bytes', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/bytes',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.text.mimeType,
      );
      expect(response.body, null);
    });
  });
}
