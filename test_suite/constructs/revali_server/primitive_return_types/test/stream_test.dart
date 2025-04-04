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
        {'data': 'Hello'},
        {'data': 'world'},
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
      expect(response.body, ['Hello', 'world']);
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
        {'data': true},
        {'data': false},
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
        {'data': 1},
        {'data': 2},
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
        {'data': 1.0},
        {'data': 2.0},
      ]);
    });

    test('record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/record',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': ['hello', 'world'],
        },
        {
          'data': ['foo', 'bar'],
        },
      ]);
    });

    test('named-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/named-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': {'first': 'hello', 'second': 'world'},
        },
        {
          'data': {'first': 'foo', 'second': 'bar'},
        },
      ]);
    });

    test('partial-record', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/partial-record',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': [
            'hello',
            {'second': 'world'},
          ],
        },
        {
          'data': [
            'foo',
            {'second': 'bar'},
          ],
        },
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
        {
          'data': [
            ['hello', 'world'],
          ],
        },
        {
          'data': [
            ['foo', 'bar'],
          ],
        },
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
        {
          'data': ['Hello'],
        },
        {
          'data': ['world'],
        },
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
        {
          'data': [
            {'hello': 1},
          ],
        },
        {
          'data': [
            {'foo': 2},
          ],
        },
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
        {
          'data': {'hello': 1},
        },
        {
          'data': {'foo': 2},
        },
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
        {
          'data': {'true': true},
        },
        {
          'data': {'false': false},
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
        {
          'data': {'Hello'},
        },
        {
          'data': {'world'},
        },
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
        {
          'data': ['Hello'],
        },
        {
          'data': ['world'],
        },
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
      expect(response.body, ['Hello', 'world']);
    });
  });
}
