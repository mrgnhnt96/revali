// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';

void main() {
  group('guard', () {
    late TestServer server;

    setUp(() {
      server = TestServer();

      createServer(server);
    });

    tearDown(() {
      server.close();
    });

    test('should allow request when no guard is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/guard/none',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'Hello world!'});
    });

    test('should reject request when guard is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/guard/reject',
      );

      expect(response.statusCode, 403);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(
        response.body,
        startsWith('''
I am a custom rejection message

__DEBUG__:
Error: GuardStopException: RejectGuard

Stack Trace:
package:revali_router/src/router/run_guards.dart'''),
      );
    });

    test('should allow request when guard is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/guard/allow',
      );

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'Hello world!'});
    });

    test(
      'should reject request when guard is present with status code',
      () async {
        final response = await server.send(
          method: 'GET',
          path: '/api/guard/reject-with-status',
        );

        expect(response.statusCode, 419);
        expect(
          response.headers.contentType?.mimeType,
          ContentType.text.mimeType,
        );
        expect(
          response.body,
          startsWith('''
I am a custom rejection message

__DEBUG__:
Error: GuardStopException: RejectGuard

Stack Trace:
package:revali_router/src/router/run_guards.dart'''),
        );
      },
    );
  });
}
