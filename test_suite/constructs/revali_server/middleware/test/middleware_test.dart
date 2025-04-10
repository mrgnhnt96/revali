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
      expect(
        response.body,
        {
          'error': 'MiddlewareStopException: StopMiddleware',
          'stackTrace': [
            'package:revali_router/src/router/run_middlewares.dart 34:34  RunMiddlewares.run',
            'package:revali_router/src/router/execute.dart 37:9           Execute.run',
            'package:revali_router/src/router/router.dart 221:12          Router._handle',
            'package:revali_router/src/router/router.dart 190:22          Router.handle',
            'package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>',
          ],
        },
      );
    });

    test('should stop request when stop middleware is present with message',
        () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/middleware/please-stop',
      );

      expect(response.statusCode, 400);
      expect(response.body, '''
please stop

__DEBUG__:
Error: MiddlewareStopException: StopMiddleware

Stack Trace:
package:revali_router/src/router/run_middlewares.dart 34:34  RunMiddlewares.run
package:revali_router/src/router/execute.dart 37:9           Execute.run
package:revali_router/src/router/router.dart 221:12          Router._handle
package:revali_router/src/router/router.dart 190:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });
  });
}
