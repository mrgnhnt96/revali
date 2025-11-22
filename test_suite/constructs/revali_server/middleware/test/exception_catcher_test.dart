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

    test('should catch exception and return successfully '
        'when no catcher is present', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/none',
      );

      expect(response.statusCode, 500);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(
        response.body,
        startsWith('''
Internal Server Error

__DEBUG__:
Error: Hello world!

Stack Trace:
routes/controllers/exception_catcher_controller.dart'''),
      );
    });

    test('should catch exception and return string successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/string',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(
        response.body,
        startsWith('''
Hello world!

__DEBUG__:
Error: Hello world!

Stack Trace:
routes/controllers/exception_catcher_controller.dart'''),
      );
    });

    test('should catch exception and return map successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/map',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      final body = {...response.body as Map};
      // ignore: avoid_dynamic_calls
      final stackTrace = body['__DEBUG__'].remove('stackTrace');

      expect(body, {
        'message': 'Hello world!',
        '__DEBUG__': {'error': '{message: Hello world!}'},
      });

      expect(
        // ignore: avoid_dynamic_calls
        stackTrace.join('\n'),
        startsWith('routes/controllers/exception_catcher_controller.dart'),
      );
    });

    test('should catch exception and return list successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/list',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      final body = [...response.body as List];
      final error = body.removeLast();
      // ignore: avoid_dynamic_calls
      final stackTrace = error['__DEBUG__'].remove('stackTrace');
      expect(body, ['a', 'b', 'c']);
      expect(error, {
        '__DEBUG__': {'error': '[a, b, c]'},
      });

      expect(
        // ignore: avoid_dynamic_calls
        stackTrace.join('\n'),
        startsWith('routes/controllers/exception_catcher_controller.dart'),
      );
    });

    test('should catch exception and return set successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/set',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      final body = [...response.body as List];
      final error = body.removeLast();
      // ignore: avoid_dynamic_calls
      final stackTrace = error['__DEBUG__'].remove('stackTrace');
      expect(body, ['hello', 'world']);
      expect(error, {
        '__DEBUG__': {'error': '{hello, world}'},
      });

      expect(
        // ignore: avoid_dynamic_calls
        stackTrace.join('\n'),
        startsWith('routes/controllers/exception_catcher_controller.dart'),
      );
    });

    test('should catch exception and return iterable successfully', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/iterable',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.json.mimeType);
      final body = [...response.body as List];
      final error = body.removeLast();
      // ignore: avoid_dynamic_calls
      final stackTrace = error['__DEBUG__'].remove('stackTrace');
      expect(body, ['Hello', 'world']);

      expect(error, {
        '__DEBUG__': {'error': '(Hello, world)'},
      });

      expect(
        // ignore: avoid_dynamic_calls
        stackTrace.join('\n'),
        startsWith('routes/controllers/exception_catcher_controller.dart'),
      );
    });

    test('should catch exception and return bool', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/bool',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(response.body, true);
    });

    test('should catch exception and return custom status code', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/exception-catcher/status-code',
      );

      expect(response.statusCode, 423);
      expect(response.headers.contentType?.mimeType, ContentType.text.mimeType);
      expect(
        response.body,
        startsWith('''
Hello world!

__DEBUG__:
Error: Hello world!

Stack Trace:
routes/controllers/exception_catcher_controller.dart'''),
      );
    });
  });
}
