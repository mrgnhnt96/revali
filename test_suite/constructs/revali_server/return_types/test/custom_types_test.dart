import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('custom-types', () {
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
        path: '/api/custom/types/user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('future-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('stream-user', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/stream-user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('list-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/list-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': [
          {'name': 'Hello world!'},
        ],
      });
    });

    test('future-list-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-list-of-users',
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
        path: '/api/custom/types/map-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'user': {'name': 'Hello world!'},
        },
      });
    });

    test('future-map-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-map-of-users',
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
        path: '/api/custom/types/record-of-users',
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
        path: '/api/custom/types/partial-record-of-users',
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

    test('future-record-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/custom/types/future-record-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {
          'name': 'Hello world!',
          'user': {'name': 'Hello world!'},
        },
      });
    });
  });
}
