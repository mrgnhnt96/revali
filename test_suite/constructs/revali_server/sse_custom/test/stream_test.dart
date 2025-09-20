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

    test('user', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/user')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': {'name': 'Hello world!'},
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': {'name': 'Hello world!'},
          }),
        ),
      ]);
    });

    test('list-of-users', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/list-of-users')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Hello world!'},
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Hello world!'},
            ],
          }),
        ),
      ]);
    });

    test('set-of-users', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/set-of-users')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Hello world!'},
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Hello world!'},
            ],
          }),
        ),
      ]);
    });

    test('iterable-of-users', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/iterable-of-users')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Hello world!'},
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Hello world!'},
            ],
          }),
        ),
      ]);
    });

    test('map-of-users', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/map-of-users')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': {
              'user': {'name': 'Hello world!'},
            },
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': {
              'user': {'name': 'Hello world!'},
            },
          }),
        ),
      ]);
    });

    test('record-of-users', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/record-of-users')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': {
              'name': 'Hello world!',
              'user': {'name': 'Hello world!'},
            },
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': {
              'name': 'Hello world!',
              'user': {'name': 'Hello world!'},
            },
          }),
        ),
      ]);
    });

    test('partial-record-of-users', () async {
      final response = await server
          .connect(method: 'GET', path: '/api/stream/partial-record-of-users')
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': [
              'Hello world!',
              {
                'user': {'name': 'Hello world!'},
              },
            ],
          }),
        ),
        utf8.encode(
          jsonEncode({
            'data': [
              'Hello world!',
              {
                'user': {'name': 'Hello world!'},
              },
            ],
          }),
        ),
      ]);
    });
  });
}
