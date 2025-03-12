import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('query-params', () {
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
        path: '/api/bananas/required?shopId=123',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123'});
    });

    test('required should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/bananas/required',
      );

      expect(response.statusCode, 500);
      expect(response.body, '''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: shopId, location: @query

Stack Trace:
.revali/server/routes/__bananas_route.dart 13:18             bananasRoute.<fn>
package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 61:13          Execute.run
package:revali_router/src/router/router.dart 178:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/bananas/optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'no shop id'});
    });

    test('all should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/bananas/all?shopId=123&shopId=456',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': '123,456'});
    });

    test('all should return error when not provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/bananas/all',
      );

      expect(response.statusCode, 500);
      expect(response.body, '''
Internal Server Error

__DEBUG__:
Error: MissingArgumentException: key: shopId, location: @query

Stack Trace:
.revali/server/routes/__bananas_route.dart 39:18             bananasRoute.<fn>
package:revali_router/src/router/execute.dart 63:24          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 61:13          Execute.run
package:revali_router/src/router/router.dart 178:22          Router.handle
package:revali_router/src/server/handle_requests.dart 28:29  handleRequests.<fn>''');
    });

    test('all-optional should return success when provided', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/bananas/all-optional',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, {'data': 'no shop ids'});
    });
  });
}
