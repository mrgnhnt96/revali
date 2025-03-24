import 'dart:convert';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('literal', () {
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
            path: '/api/literal/user',
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
            path: '/api/literal/list-of-users',
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
            path: '/api/literal/set-of-users',
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
            path: '/api/literal/iterable-of-users',
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
            path: '/api/literal/map-of-users',
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
            path: '/api/literal/record-of-users',
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
            path: '/api/literal/partial-record-of-users',
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
