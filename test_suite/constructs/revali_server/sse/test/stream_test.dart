import 'dart:convert';

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
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/data-string',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 'Hello'})),
        utf8.encode(jsonEncode({'data': 'world'})),
      ]);
    });

    test('string', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/string',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode('Hello'),
        utf8.encode('world'),
      ]);
    });

    test('bool', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/bool',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': true})),
        utf8.encode(jsonEncode({'data': false})),
      ]);
    });

    test('int', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/int',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 1})),
        utf8.encode(jsonEncode({'data': 2})),
      ]);
    });

    test('double', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/double',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 1.0})),
        utf8.encode(jsonEncode({'data': 2.0})),
      ]);
    });

    test('record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/record',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['hello', 'world'],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': ['foo', 'bar'],
          }),
        ),
      ]);
    });

    test('named-record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/named-record',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': {
              'first': 'hello',
              'second': 'world',
            },
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': {
              'first': 'foo',
              'second': 'bar',
            },
          }),
        ),
      ]);
    });

    test('partial-record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/partial-record',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': [
              'hello',
              {
                'second': 'world',
              },
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              'foo',
              {
                'second': 'bar',
              },
            ],
          }),
        ),
      ]);
    });

    test('list-of-records', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/list-of-records',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': [
              ['hello', 'world'],
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              ['foo', 'bar'],
            ],
          }),
        ),
      ]);
    });

    test('list-of-strings', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/list-of-strings',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['Hello'],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': ['world'],
          }),
        ),
      ]);
    });

    test('list-of-maps', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/list-of-maps',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': [
              {'hello': 1},
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              {'foo': 2},
            ],
          }),
        ),
      ]);
    });

    test('map-string-dynamic', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/map-string-dynamic',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': {'hello': 1},
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': {'foo': 2},
          }),
        ),
      ]);
    });

    test('map-dynamic-dynamic', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/map-dynamic-dynamic',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': {'true': true},
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': {'false': false},
          }),
        ),
      ]);
    });

    test('set', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/set',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['Hello'],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': ['world'],
          }),
        ),
      ]);
    });

    test('iterable', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/iterable',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['Hello'],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': ['world'],
          }),
        ),
      ]);
    });

    test('bytes', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/stream/bytes',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode('Hello'),
        utf8.encode('world'),
      ]);
    });
  });
}
