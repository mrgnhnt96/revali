import 'dart:convert';

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

    test('void', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/void',
      );

      final responses = await stream.toList();

      expect(responses, isEmpty);
    });

    test('data-string', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/data-string',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 'Hello world!'})),
      ]);
    });

    test('string', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/string',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode('Hello world!'),
      ]);
    });

    test('bool', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/bool',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': true})),
      ]);
    });

    test('int', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/int',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 1})),
      ]);
    });

    test('double', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/double',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 1.0})),
      ]);
    });

    test('record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/record',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['hello', 'world'],
          }),
        ),
      ]);
    });

    test('named-record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/named-record',
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
      ]);
    });

    test('partial-record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/partial-record',
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
      ]);
    });

    test('list-of-records', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/list-of-records',
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
      ]);
    });

    test('list-of-strings', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/list-of-strings',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['Hello world!'],
          }),
        ),
      ]);
    });

    test('list-of-maps', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/list-of-maps',
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
      ]);
    });

    test('map-string-dynamic', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/map-string-dynamic',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': {'hello': 1},
          }),
        ),
      ]);
    });

    test('map-dynamic-dynamic', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/map-dynamic-dynamic',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': {'true': true},
          }),
        ),
      ]);
    });

    test('set', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/set',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['Hello world!'],
          }),
        ),
      ]);
    });

    test('iterable', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/literals/iterable',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(
          jsonEncode({
            'data': ['Hello world!'],
          }),
        ),
      ]);
    });

    test('bytes', () async {
      final result = await server
          .connect(
            method: 'GET',
            path: '/api/literals/bytes',
          )
          .single;

      final decoded = utf8.decode(result);

      expect(decoded, 'Hello world!');
    });
  });
}
