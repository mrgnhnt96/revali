import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Claims the HttpError below, to prove an app's catcher still wins.
final class _Claiming extends ExceptionCatcher<HttpError> {
  const _Claiming();

  @override
  ExceptionCatcherResult<HttpError> catchException(
    HttpError exception,
    Context context,
  ) {
    return ExceptionCatcherResult.handled(
      statusCode: 418,
      body: {'handled': exception.code},
    );
  }
}

void main() {
  group('HttpError', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> serve({
      List<ExceptionCatcher<dynamic>> catchers = const [],
    }) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      final router = Router(
        globalComponents: LifecycleComponentsImpl(catchers: catchers),
        routes: [
          Route(
            'missing',
            method: 'GET',
            handler: (context) async {
              throw const HttpError.notFound(
                code: 'user_not_found',
                message: 'No user with that id',
                details: {'id': 7},
              );
            },
          ),
          Route(
            'bare',
            method: 'GET',
            handler: (context) async {
              throw const HttpError.conflict(
                code: 'already_exists',
                message: 'Taken',
              );
            },
          ),
          Route(
            'boom',
            method: 'GET',
            handler: (context) async => throw StateError('unexpected'),
          ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));
    }

    Future<(int, String)> get(String path) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}$path'),
      );
      final response = await request.close();

      return (
        response.statusCode,
        await response.transform(utf8.decoder).join(),
      );
    }

    setUp(() => client = HttpClient());

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('responds with its own status', () async {
      await serve();

      expect((await get('/missing')).$1, HttpStatus.notFound);
      expect((await get('/bare')).$1, HttpStatus.conflict);
    });

    test('responds with the error envelope', () async {
      await serve();

      final (_, body) = await get('/missing');
      final decoded = jsonDecode(body) as Map<String, dynamic>;

      expect(decoded['error'], {
        'code': 'user_not_found',
        'message': 'No user with that id',
        'details': {'id': 7},
      });
    });

    test('omits details when there are none', () async {
      await serve();

      final (_, body) = await get('/bare');
      final error = (jsonDecode(body) as Map)['error'] as Map;

      expect(error.containsKey('details'), isFalse);
    });

    test('leaves an ordinary exception on the default response', () async {
      await serve();

      final (status, body) = await get('/boom');

      // Nothing about the existing plain-text defaults changes, which is what
      // keeps this opt-in rather than breaking every current client.
      expect(status, HttpStatus.internalServerError);
      expect(body, isNot(contains('"error"')));
    });

    test('an app catcher still wins', () async {
      await serve(catchers: const [_Claiming()]);

      final (status, body) = await get('/missing');

      // The envelope is a fallback for an unclaimed HttpError, not an
      // override of an app that handles its own.
      expect(status, 418);
      expect((jsonDecode(body) as Map)['handled'], 'user_not_found');
    });
  });

  group('HttpError.toEnvelope', () {
    test('nests under error', () {
      const error = HttpError.badRequest(code: 'bad', message: 'nope');

      expect(error.toEnvelope(), {
        'error': {'code': 'bad', 'message': 'nope'},
      });
    });

    test('carries the status each constructor implies', () {
      expect(
        const HttpError.badRequest(code: 'c', message: 'm').statusCode,
        400,
      );
      expect(
        const HttpError.unauthorized(code: 'c', message: 'm').statusCode,
        401,
      );
      expect(
        const HttpError.forbidden(code: 'c', message: 'm').statusCode,
        403,
      );
      expect(const HttpError.notFound(code: 'c', message: 'm').statusCode, 404);
      expect(const HttpError.conflict(code: 'c', message: 'm').statusCode, 409);
      expect(
        const HttpError.unprocessable(code: 'c', message: 'm').statusCode,
        422,
      );
      expect(const HttpError.internal(code: 'c', message: 'm').statusCode, 500);
    });
  });
}
