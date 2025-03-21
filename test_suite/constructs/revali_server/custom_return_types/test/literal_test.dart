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
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('list-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/list-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': [
          {'name': 'Hello world!'},
        ],
      });
    });

    test('set-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/set-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': [
          {'name': 'Hello world!'},
        ],
      });
    });

    test('iterable-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/iterable-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': [
          {'name': 'Hello world!'},
        ],
      });
    });

    test('map-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/map-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'user': {'name': 'Hello world!'},
        },
      });
    });

    test('record-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/record-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'name': 'Hello world!',
          'user': {'name': 'Hello world!'},
        },
      });
    });

    test('partial-record-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/literal/partial-record-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': [
          'Hello world!',
          {
            'user': {'name': 'Hello world!'},
          },
        ],
      });
    });
  });
}
