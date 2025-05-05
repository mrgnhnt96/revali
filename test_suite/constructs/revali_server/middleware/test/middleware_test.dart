// ignore_for_file: lines_longer_than_80_chars

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('middleware', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('should allow request when read middleware is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/middleware/read',
        headers: {
          'auth': 'sup dude',
        },
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'sup dude'});
      expect(response.headers['x-auth'], isNull);
    });

    test('should allow request when write middleware is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/middleware/write',
        headers: {
          'auth': 'sup dude',
        },
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'sup dude'});
      expect(response.headers['x-auth'], ['sup dude']);
    });

    test('should allow request when its fine middleware is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/middleware/its-fine',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'yo yo yo'});
      expect(response.headers['x-auth'], ['yo yo yo']);
    });

    test('should stop request when stop middleware is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/middleware/stop',
      );

      expect(response.statusCode, 400);
      // ignore: avoid_dynamic_calls
      final error = response.body['error'] as String;
      // ignore: avoid_dynamic_calls
      final stackTrace = (response.body['stackTrace'] as List).first as String;
      expect(error, 'MiddlewareStopException: StopMiddleware');
      expect(
        stackTrace,
        startsWith('package:revali_router/src/router/run_middlewares.dart'),
      );
    });

    test('should stop request when stop middleware is present with message',
        () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/middleware/please-stop',
      );

      expect(response.statusCode, 400);
      expect(
        response.body,
        startsWith('''
please stop

__DEBUG__:
Error: MiddlewareStopException: StopMiddleware

Stack Trace:
package:revali_router/src/router/run_middlewares.dart'''),
      );
    });
  });
}
