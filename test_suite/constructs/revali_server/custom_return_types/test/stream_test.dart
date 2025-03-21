import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main1() {
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
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/user',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': {'name': 'Hello world!'},
        },
        {
          'data': {'name': 'Hello world!'},
        }
      ]);
    });

    test('list-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/list-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': [
            {'name': 'Hello world!'},
          ],
        },
        {
          'data': [
            {'name': 'Hello world!'},
          ],
        },
      ]);
    });

    test('set-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/set-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': [
            {'name': 'Hello world!'},
          ],
        },
        {
          'data': [
            {'name': 'Hello world!'},
          ],
        },
      ]);
    });

    test('iterable-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/iterable-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': [
            {'name': 'Hello world!'},
          ],
        },
        {
          'data': [
            {'name': 'Hello world!'},
          ],
        },
      ]);
    });

    test('map-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/map-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': {
            'user': {'name': 'Hello world!'},
          },
        },
        {
          'data': {
            'user': {'name': 'Hello world!'},
          },
        },
      ]);
    });

    test('record-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/record-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': {
            'name': 'Hello world!',
            'user': {'name': 'Hello world!'},
          },
        },
        {
          'data': {
            'name': 'Hello world!',
            'user': {'name': 'Hello world!'},
          },
        },
      ]);
    });

    test('partial-record-of-users', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/stream/partial-record-of-users',
      );

      expect(response.statusCode, 200);
      expect(response.body, [
        {
          'data': [
            'Hello world!',
            {
              'user': {'name': 'Hello world!'},
            },
          ],
        },
        {
          'data': [
            'Hello world!',
            {
              'user': {'name': 'Hello world!'},
            },
          ],
        }
      ]);
    });
  });
}
