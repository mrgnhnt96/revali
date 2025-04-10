import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('header-params', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('required should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/required',
        headers: {'X-Shop-Id': '123'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('required should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/required',
      );

      expect(response.statusCode, 500);
      expect(response.body, '''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: X-Shop-Id, location: @header

Stack Trace:
.revali/server/routes/__header_route.dart 17:15              headerRoute.<fn>
package:revali_router/src/router/execute.dart 61:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 59:13          Execute.run
package:revali_router/src/router/router.dart 221:12          Router._handle
package:revali_router/src/router/router.dart 190:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/optional',
        headers: {'X-Shop-Id': '123'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('all should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all',
        headers: {'X-Shop-Id': '123,456'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });

    test('all should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all',
      );

      expect(response.statusCode, 500);
      expect(response.body, '''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: X-Shop-Id, location: @header (all)

Stack Trace:
.revali/server/routes/__header_route.dart 57:15              headerRoute.<fn>
package:revali_router/src/router/execute.dart 61:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 59:13          Execute.run
package:revali_router/src/router/router.dart 221:12          Router._handle
package:revali_router/src/router/router.dart 190:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('all-optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/header/all-optional',
        headers: {'X-Shop-Id': '123,456'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });
  });
}
