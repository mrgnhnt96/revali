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

    test('user', () async {
      final response = await server
          .connect(
            method: 'GET',
            path: '/api/future/user',
          )
          .toList();

      expect(response, [
        utf8.encode(
          jsonEncode({
            'data': {'name': 'Hello world!'},
          }),
        ),
      ]);
    });

    test('list-of-users', () async {
      final response = await server
          .connect(
            method: 'GET',
            path: '/api/future/list-of-users',
          )
          .toList();

      expect(response, [
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
          .connect(
            method: 'GET',
            path: '/api/future/set-of-users',
          )
          .toList();

      expect(response, [
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
          .connect(
            method: 'GET',
            path: '/api/future/iterable-of-users',
          )
          .toList();

      expect(response, [
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
          .connect(
            method: 'GET',
            path: '/api/future/map-of-users',
          )
          .toList();

      expect(response, [
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
          .connect(
            method: 'GET',
            path: '/api/future/record-of-users',
          )
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
      ]);
    });

    test('partial-record-of-users', () async {
      final response = await server
          .connect(
            method: 'GET',
            path: '/api/future/partial-record-of-users',
          )
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
      ]);
    });
  });
}
