import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('allow-origin', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();

      await createServer(server);
    });

    tearDown(() {
      server.close();
    });

    group('all', () {
      test(
        'returns a successful response when origin is not present',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/allow-origin/all',
          );

          expect(response.statusCode, 200);
          expect(response.headers['access-control-allow-origin'], ['*']);
        },
      );

      test('returns a successful response when origin is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/all',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 200);
        expect(response.headers['access-control-allow-origin'], [
          'https://zelda.com',
        ]);
      });

      test('should maintain origin when error occurs', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/fail',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 500);
        expect(response.headers['access-control-allow-origin'], [
          'https://zelda.com',
        ]);
      });
    });

    group('inherited', () {
      test('returns a successful response when origin is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/inherited',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 200);
        expect(response.headers['access-control-allow-origin'], [
          'https://zelda.com',
        ]);
      });

      test('allows a request with no origin at all', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/inherited',
        );

        // A request with no Origin is not a cross-origin browser request,
        // so origin allowlisting does not apply to it -- see
        // "fix: stop rejecting requests with no Origin header under
        // restrictive AllowOrigins". Locking these out would also lock out
        // every curl / mobile / server-to-server caller of the endpoint.
        expect(response.statusCode, 200);
        expect(response.headers['access-control-allow-origin'], ['*']);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/allow-origin/inherited',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 200);
        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-origin'),
          'https://zelda.com',
        );
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/allow-origin/inherited',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 200);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-origin'),
          'https://zelda.com',
        );
      });
    });

    group('not-inherited', () {
      test('returns an error response when parent origin is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/not-inherited',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 403);
      });

      test('allows a request with no origin at all', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/not-inherited',
        );

        expect(response.statusCode, 200);
        expect(response.headers['access-control-allow-origin'], ['*']);
      });

      test('returns a successful response when origin is present', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/not-inherited',
          headers: {'Origin': 'https://link.com'},
        );

        expect(response.statusCode, 200);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/allow-origin/not-inherited',
          headers: {'Origin': 'https://link.com'},
        );

        expect(response.statusCode, 200);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-origin'),
          'https://link.com',
        );
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/allow-origin/not-inherited',
          headers: {'Origin': 'https://link.com'},
        );

        expect(response.statusCode, 200);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-origin'),
          'https://link.com',
        );
      });
    });

    group('combined', () {
      test(
        'returns a successful response when parent origin is present',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/allow-origin/combined',
            headers: {'Origin': 'https://zelda.com'},
          );

          expect(response.statusCode, 200);
        },
      );

      test(
        'returns a successful response when child origin is present',
        () async {
          final response = await server.send(
            method: 'GET',
            path: '/api/allow-origin/combined',
            headers: {'Origin': 'https://link.com'},
          );

          expect(response.statusCode, 200);
        },
      );

      test('allows a request with neither child nor parent origin', () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/allow-origin/combined',
        );

        expect(response.statusCode, 200);
        expect(response.headers['access-control-allow-origin'], ['*']);
      });

      test('returns a successful response when OPTIONS request', () async {
        final response = await server.send(
          method: 'OPTIONS',
          path: '/api/allow-origin/combined',
          headers: {'Origin': 'https://zelda.com'},
        );

        expect(response.statusCode, 200);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-origin'),
          'https://zelda.com',
        );
      });

      test('returns a successful response when HEAD request', () async {
        final response = await server.send(
          method: 'HEAD',
          path: '/api/allow-origin/combined',
          headers: {'Origin': 'https://link.com'},
        );

        expect(response.statusCode, 200);

        final headers = {...response.headers.values};

        expect(
          headers.remove('access-control-allow-origin'),
          'https://link.com',
        );
      });
    });
  });
}
