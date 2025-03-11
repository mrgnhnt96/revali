// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('exception catcher', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test(
        'should catch exception and return successfully '
        'when no catcher is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/none',
      );

      expect(response.statusCode, 500);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, '''
Internal Server Error

__DEBUG__:
Error: Hello world!

Stack Trace:
routes/controllers/exception_catcher_controller.dart 10:5    ExceptionCatcherController.none
.revali/server/routes/__exception_catcher_route.dart 14:38   exceptionCatcherRoute.<fn>
package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 61:13          Execute.run
package:revali_router/src/router/router.dart 178:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('should catch exception and return string successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/string',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, '''
Hello world!

__DEBUG__:
Error: Hello world!

Stack Trace:
routes/controllers/exception_catcher_controller.dart 16:5    ExceptionCatcherController.handle
.revali/server/routes/__exception_catcher_route.dart 22:38   exceptionCatcherRoute.<fn>
package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 61:13          Execute.run
package:revali_router/src/router/router.dart 178:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('should catch exception and return map successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/map',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, {
        'message': 'Hello world!',
        '__DEBUG__': {
          'error': '{message: Hello world!}',
          'stackTrace': [
            'routes/controllers/exception_catcher_controller.dart 22:5    ExceptionCatcherController.handleObject',
            '.revali/server/routes/__exception_catcher_route.dart 30:38   exceptionCatcherRoute.<fn>',
            'package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>',
            'dart:async                                                   runZonedGuarded',
            'package:revali_router/src/router/execute.dart 61:13          Execute.run',
            'package:revali_router/src/router/router.dart 178:22          Router.handle',
            'package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>',
          ],
        },
      });
    });

    test('should catch exception and return list successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/list',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, [
        1,
        2,
        3,
        {
          '__DEBUG__': {
            'error': '[1, 2, 3]',
            'stackTrace': [
              'routes/controllers/exception_catcher_controller.dart 30:5    ExceptionCatcherController.handleList',
              '.revali/server/routes/__exception_catcher_route.dart 38:38   exceptionCatcherRoute.<fn>',
              'package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>',
              'dart:async                                                   runZonedGuarded',
              'package:revali_router/src/router/execute.dart 61:13          Execute.run',
              'package:revali_router/src/router/router.dart 178:22          Router.handle',
              'package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>',
            ],
          },
        }
      ]);
    });

    test('should catch exception and return set successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/set',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, [
        'hello',
        'world',
        {
          '__DEBUG__': {
            'error': '{hello, world}',
            'stackTrace': [
              'routes/controllers/exception_catcher_controller.dart 36:5    ExceptionCatcherController.handleSet',
              '.revali/server/routes/__exception_catcher_route.dart 46:38   exceptionCatcherRoute.<fn>',
              'package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>',
              'dart:async                                                   runZonedGuarded',
              'package:revali_router/src/router/execute.dart 61:13          Execute.run',
              'package:revali_router/src/router/router.dart 178:22          Router.handle',
              'package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>',
            ],
          },
        }
      ]);
    });

    test('should catch exception and return iterable successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/iterable',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      expect(response.body, [
        'Hello',
        'world',
        {
          '__DEBUG__': {
            'error': '(Hello, world)',
            'stackTrace': [
              'routes/controllers/exception_catcher_controller.dart 47:5    ExceptionCatcherController.handleIterable',
              '.revali/server/routes/__exception_catcher_route.dart 54:38   exceptionCatcherRoute.<fn>',
              'package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>',
              'dart:async                                                   runZonedGuarded',
              'package:revali_router/src/router/execute.dart 61:13          Execute.run',
              'package:revali_router/src/router/router.dart 178:22          Router.handle',
              'package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>',
            ],
          },
        }
      ]);
    });

    test('should catch exception and return bool with internal error',
        () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/bool',
      );

      expect(response.statusCode, 500);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, '''
Internal Server Error

__DEBUG__:
Error: Unsupported operation: Unsupported body data type: true

Stack Trace:
routes/controllers/exception_catcher_controller.dart 53:5    ExceptionCatcherController.handleBool
.revali/server/routes/__exception_catcher_route.dart 62:38   exceptionCatcherRoute.<fn>
package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 61:13          Execute.run
package:revali_router/src/router/router.dart 178:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('should catch exception and return custom status code', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/status-code',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, '''
Hello world!

__DEBUG__:
Error: Hello world!

Stack Trace:
routes/controllers/exception_catcher_controller.dart 59:5    ExceptionCatcherController.handleStatusCode
.revali/server/routes/__exception_catcher_route.dart 70:38   exceptionCatcherRoute.<fn>
package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 61:13          Execute.run
package:revali_router/src/router/router.dart 178:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });
  });
}
