// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('future', () {
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
        path: '/api/future/void',
      );

      final responses = await stream.toList();

      expect(responses, isEmpty);
    });

    test('data-string', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/data-string',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 'Hello world!'})),
      ]);
    });

    test('string', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/string',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode('Hello world!'),
      ]);
    });

    test('bool', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/bool',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': true})),
      ]);
    });

    test('int', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/int',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 1})),
      ]);
    });

    test('double', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/double',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode(jsonEncode({'data': 1.0})),
      ]);
    });

    test('record', () async {
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/record',
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
        path: '/api/future/named-record',
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
        path: '/api/future/partial-record',
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
        path: '/api/future/list-of-records',
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
        path: '/api/future/list-of-strings',
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
        path: '/api/future/list-of-maps',
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
        path: '/api/future/map-string-dynamic',
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
        path: '/api/future/map-dynamic-dynamic',
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
        path: '/api/future/set',
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
        path: '/api/future/iterable',
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
      final stream = server.connect(
        method: 'GET',
        path: '/api/future/bytes',
      );

      final responses = await stream.toList();

      expect(responses, [
        utf8.encode('Hello world!'),
      ]);
    });
  });
}
