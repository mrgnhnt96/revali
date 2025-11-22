import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('prevent-headers', () {
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
        path: '/api/prevent-headers/inherited',
        headers: {'access-control-request-headers': 'request-header'},
      );

      expect(response.statusCode, 200);

      final headers = {...response.headers.values};

      expect(headers.remove('access-control-allow-headers'), 'request-header');
    });

    group('inherited', () {
      test(
        'returns a successful response when header is not present',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/prevent-headers/inherited',
          );

          expect(response.statusCode, 200);
        },
      );

      test('returns an error response when header is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/prevent-headers/inherited',
          headers: {'X-Parent-Header': 'test'},
        );

        expect(response.statusCode, 403);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/prevent-headers/inherited',
        );

        expect(response.statusCode, 200);
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/prevent-headers/inherited',
        );

        expect(response.statusCode, 200);
      });
    });

    group('not-inherited', () {
      test(
        'returns a successful response when parent header is present',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/prevent-headers/not-inherited',
            headers: {'X-Parent-Header': 'test'},
          );

          expect(response.statusCode, 200);
        },
      );

      test(
        'returns a successful response when child header is not present',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/prevent-headers/not-inherited',
          );

          expect(response.statusCode, 200);
        },
      );

      test('returns an error response when header is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/prevent-headers/not-inherited',
          headers: {'X-My-Header': 'test'},
        );

        expect(response.statusCode, 403);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/prevent-headers/not-inherited',
        );

        expect(response.statusCode, 200);
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/prevent-headers/not-inherited',
        );

        expect(response.statusCode, 200);
      });
    });

    group('combined', () {
      test('returns an error response when parent header is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/prevent-headers/combined',
          headers: {'X-Parent-Header': 'test'},
        );

        expect(response.statusCode, 403);
      });

      test('returns an error response when child header is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/prevent-headers/combined',
          headers: {'X-My-Header': 'test'},
        );

        expect(response.statusCode, 403);
      });

      test('returns a successful response when child & parent header '
          'are not present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/prevent-headers/combined',
        );

        expect(response.statusCode, 200);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/prevent-headers/combined',
        );

        expect(response.statusCode, 200);
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/prevent-headers/combined',
        );

        expect(response.statusCode, 200);
      });
    });
  });
}
