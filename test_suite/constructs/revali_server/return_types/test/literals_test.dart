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
      expect(response.body, {'data': 'Hello world!'});
    });

    test('string', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/string',
      );

      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, 'Hello world!');
    });

    test('bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/bool',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': true});
    });

    test('int', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/int',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': 1});
    });

    test('double', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/double',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {'data': 1});
    });

    test('record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/record',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': ['hello', 'world'],
      });
    });

    test('named-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/named-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'first': 'hello',
          'second': 'world',
        },
      });
    });

    test('partial-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/partial-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': [
          'hello',
          {
            'second': 'world',
          },
        ],
      });
    });

    test('list-of-records', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/list-of-records',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': [
          ['hello', 'world'],
        ],
      });
    });

    test('list-of-strings', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/list-of-strings',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': ['Hello world!'],
      });
    });

    test('list-of-maps', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/list-of-maps',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': [
          {'hello': 1},
        ],
      });
    });

    test('map-string-dynamic', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/map-string-dynamic',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': {'hello': 1},
      });
    });

    test('map-dynamic-dynamic', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/map-dynamic-dynamic',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': {'true': true},
      });
    });

    test('set', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/set',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': ['Hello world!'],
      });
    });

    test('iterable', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/iterable',
      );

      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'data': ['Hello world!'],
      });
    });

    test('stream-data-string', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/stream-string',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, {'data': 'Hello world!'});
    });

    test('stream-string', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/stream-string',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, 'Hello world!');
    });

    test('bytes', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/bytes',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, 'Hello world!');
    });

    test('stream-bytes', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literals/stream-bytes',
      );

      expect(
        response.headers.contentType?.mimeType,
        ContentType.parse('application/octet-stream').mimeType,
      );
      expect(response.body, 'Hello world!');
    });
  });
}
