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
      final response = await server.send(
        method: 'GET',
        path: '/api/future/user',
      );

      expect(response.statusCode, 200);
      expect(response.body, {
        'data': {'name': 'Hello world!'},
      });
    });

    test('list-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/future/list-of-users',
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
        path: '/api/future/set-of-users',
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
        path: '/api/future/iterable-of-users',
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
        path: '/api/future/map-of-users',
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
        path: '/api/future/record-of-users',
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
        path: '/api/future/partial-record-of-users',
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
