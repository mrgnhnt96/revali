import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('expect-headers', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('should include request headers in the response', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/expect-headers',
        headers: {
          'access-control-request-headers': 'request-header',
          'X-My-Header': 'test',
        },
      );

      expect(response.statusCode, 200);

      final headers = {...response.headers.values};

      expect(
        headers.remove('access-control-allow-headers'),
        'X-My-Header, request-header',
      );
    });

    group('single', () {
      test('returns a successful response when header is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/expect-headers',
          headers: {'X-My-Header': 'test'},
        );

        expect(response.statusCode, 200);
      });

      test('returns an error response when header is missing', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/expect-headers',
        );

        expect(response.statusCode, 403);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/expect-headers',
          headers: {'X-My-Header': 'test'},
        );

        expect(response.statusCode, 200);
        expect(response.body, isNull);

        final headers = {...response.headers.values};

        expect(headers.remove('access-control-allow-headers'), 'X-My-Header');
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/expect-headers',
          headers: {'X-My-Header': 'test'},
        );

        expect(response.statusCode, 200);
        expect(response.body, isNull);

        final headers = {...response.headers.values};

        expect(headers.remove('access-control-allow-headers'), 'X-My-Header');
      });
    });

    group('many', () {
      test('returns a successful response when header is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/expect-headers/many',
          headers: {'X-My-Header': 'test', 'X-Another-Header': 'test'},
        );

        expect(response.statusCode, 200);
      });

      test('returns an error response when header is missing one', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/expect-headers/many',
          headers: {'X-My-Header': 'test'},
        );

        expect(response.statusCode, 403);
      });

      test(
        'returns an error response when header is missing the other one',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/expect-headers/many',
            headers: {'X-Another-Header': 'test'},
          );

          expect(response.statusCode, 403);
        },
      );

      test('returns an error response when header is missing both', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/expect-headers/many',
        );

        expect(response.statusCode, 403);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/expect-headers/many',
          headers: {'X-My-Header': 'test', 'X-Another-Header': 'test'},
        );

        expect(response.statusCode, 200);
        expect(response.body, isNull);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-headers'),
          'X-My-Header, X-Another-Header',
        );
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/expect-headers/many',
          headers: {'X-My-Header': 'test', 'X-Another-Header': 'test'},
        );

        expect(response.statusCode, 200);
        expect(response.body, isNull);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-headers'),
          'X-My-Header, X-Another-Header',
        );
      });
    });
  });
}
