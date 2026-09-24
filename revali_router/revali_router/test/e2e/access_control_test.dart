import 'dart:async';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// Drives the router through a real `dart:io` server, because what these
/// checks see depends on how `dart:io` delivers a request -- notably, it
/// lowercases every incoming header name.
void main() {
  group('access control', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> startServer({
      required List<BaseRoute> routes,
      LifecycleComponentsImpl? globalComponents,
    }) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      final router = Router(
        routes: routes,
        globalComponents: globalComponents,
      );

      unawaited(handleRouterRequests(server, router, server.close));
    }

    Future<HttpClientResponse> send(
      String path, {
      String method = 'GET',
      Map<String, String> headers = const {},
    }) async {
      final request = await client.openUrl(
        method,
        Uri.parse('http://${server.address.host}:${server.port}/$path'),
      );
      for (final MapEntry(:key, :value) in headers.entries) {
        request.headers.set(key, value, preserveHeaderCase: true);
      }
      final response = await request.close();
      await response.drain<void>();
      return response;
    }

    Route endpoint(
      String path, {
      String method = 'GET',
      AllowOrigins? allowedOrigins,
      PreventHeaders? preventedHeaders,
      ExpectHeaders? expectedHeaders,
    }) {
      return Route(
        path,
        method: method,
        allowedOrigins: allowedOrigins,
        preventedHeaders: preventedHeaders,
        expectedHeaders: expectedHeaders,
        handler: (context) async {
          context.response.body = 'ok';
        },
      );
    }

    setUp(() {
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    group('origin matching', () {
      Future<int> statusFor(Set<String> origins, String origin) async {
        await startServer(
          routes: [endpoint('data', allowedOrigins: AllowOrigins(origins))],
        );
        final response = await send('data', headers: {'origin': origin});
        await server.close(force: true);
        return response.statusCode;
      }

      test('a plain origin does not admit an origin that only contains it',
          () async {
        expect(
          await statusFor({'https://myapp.com'}, 'https://myapp.com.evil.io'),
          HttpStatus.forbidden,
        );
      });

      test('a plain origin does not treat its dots as wildcards', () async {
        expect(
          await statusFor(
            {'https://admin.myapp.com'},
            'https://adminxmyapp.com',
          ),
          HttpStatus.forbidden,
        );
      });

      test('a client-sent Access-Control-Allow-Origin is not read as the '
          'origin', () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              allowedOrigins: const AllowOrigins({'https://myapp.com'}),
            ),
          ],
        );

        final response = await send(
          'data',
          headers: {
            'origin': 'https://evil.io',
            'access-control-allow-origin': 'https://myapp.com',
          },
        );

        expect(response.statusCode, 403);
      });

      test('a plain origin still admits itself exactly', () async {
        expect(
          await statusFor({'https://myapp.com'}, 'https://myapp.com'),
          HttpStatus.ok,
        );
      });

      test('a regular expression (starting with ^) must match the whole origin',
          () async {
        expect(
          await statusFor(
            {r'^https://[a-z]+\.myapp\.com'},
            'https://a.myapp.com',
          ),
          HttpStatus.ok,
        );
        expect(
          await statusFor(
            {r'^https://[a-z]+\.myapp\.com'},
            'https://a.myapp.com.evil.io',
          ),
          HttpStatus.forbidden,
        );
      });

      test('* admits any origin', () async {
        expect(
          await statusFor({'*'}, 'https://anything.io'),
          HttpStatus.ok,
        );
      });
    });

    group('app-level annotations', () {
      test('@AllowOrigins on the app restricts an endpoint without its own',
          () async {
        await startServer(
          globalComponents: LifecycleComponentsImpl(
            allowedOrigins: const AllowOrigins({'https://myapp.com'}),
          ),
          routes: [endpoint('data')],
        );

        final denied =
            await send('data', headers: {'origin': 'https://evil.io'});
        expect(denied.statusCode, HttpStatus.forbidden);

        final allowed =
            await send('data', headers: {'origin': 'https://myapp.com'});
        expect(allowed.statusCode, HttpStatus.ok);
      });

      test('@AllowOrigins on the app combines with a controller-level one',
          () async {
        await startServer(
          globalComponents: LifecycleComponentsImpl(
            allowedOrigins: const AllowOrigins({'https://myapp.com'}),
          ),
          routes: [
            Route(
              'api',
              allowedOrigins: const AllowOrigins({'https://partner.com'}),
              routes: [endpoint('data')],
            ),
          ],
        );

        final fromApp =
            await send('api/data', headers: {'origin': 'https://myapp.com'});
        expect(fromApp.statusCode, HttpStatus.ok);

        final fromController =
            await send('api/data', headers: {'origin': 'https://partner.com'});
        expect(fromController.statusCode, HttpStatus.ok);

        final denied =
            await send('api/data', headers: {'origin': 'https://evil.io'});
        expect(denied.statusCode, HttpStatus.forbidden);
      });

      test('a controller-level noInherit drops the app-level origins',
          () async {
        await startServer(
          globalComponents: LifecycleComponentsImpl(
            allowedOrigins: const AllowOrigins({'https://myapp.com'}),
          ),
          routes: [
            Route(
              'api',
              allowedOrigins:
                  const AllowOrigins.noInherit({'https://partner.com'}),
              routes: [endpoint('data')],
            ),
          ],
        );

        final fromApp =
            await send('api/data', headers: {'origin': 'https://myapp.com'});
        expect(fromApp.statusCode, HttpStatus.forbidden);
      });

      test('@PreventHeaders on the app applies to an endpoint without its own',
          () async {
        await startServer(
          globalComponents: LifecycleComponentsImpl(
            preventedHeaders: const PreventHeaders({'x-debug'}),
          ),
          routes: [endpoint('data')],
        );

        final response = await send('data', headers: {'x-debug': '1'});
        expect(response.statusCode, HttpStatus.forbidden);
      });
    });

    group('header name case', () {
      test('@PreventHeaders matches regardless of the case it is written in',
          () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              preventedHeaders: const PreventHeaders({'X-Debug'}),
            ),
          ],
        );

        final response = await send('data', headers: {'X-Debug': '1'});
        expect(response.statusCode, HttpStatus.forbidden);
      });

      test('@ExpectHeaders matches regardless of the case it is written in',
          () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              expectedHeaders: const ExpectHeaders({'X-Client-Id'}),
            ),
          ],
        );

        final missing = await send('data');
        expect(missing.statusCode, HttpStatus.forbidden);

        final present = await send('data', headers: {'X-Client-Id': 'abc'});
        expect(present.statusCode, HttpStatus.ok);
      });
    });

    group('preflight', () {
      Map<String, String> preflightHeaders(String requested) => {
            'origin': 'https://myapp.com',
            'access-control-request-method': 'GET',
            'access-control-request-headers': requested,
          };

      test('is not rejected by @ExpectHeaders', () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              expectedHeaders: const ExpectHeaders({'X-Client-Id'}),
            ),
          ],
        );

        final response = await send(
          'data',
          method: 'OPTIONS',
          headers: preflightHeaders('x-client-id'),
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(
          response.headers
              .value(HttpHeaders.accessControlAllowHeadersHeader)
              ?.toLowerCase(),
          contains('x-client-id'),
        );
      });

      test('still enforces @AllowOrigins', () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              allowedOrigins: const AllowOrigins({'https://other.com'}),
            ),
          ],
        );

        final response = await send(
          'data',
          method: 'OPTIONS',
          headers: preflightHeaders('content-type'),
        );

        expect(response.statusCode, HttpStatus.forbidden);
      });

      test('does not advertise a prevented header as allowed', () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              preventedHeaders: const PreventHeaders({'x-debug'}),
            ),
          ],
        );

        final response = await send(
          'data',
          method: 'OPTIONS',
          headers: preflightHeaders('x-debug, content-type'),
        );

        expect(response.statusCode, HttpStatus.ok);
        final allowed = response.headers
            .value(HttpHeaders.accessControlAllowHeadersHeader)
            ?.toLowerCase();
        expect(allowed, isNot(contains('x-debug')));
        expect(allowed, contains('content-type'));
      });

      test('a plain OPTIONS request is still subject to @ExpectHeaders',
          () async {
        await startServer(
          routes: [
            endpoint(
              'data',
              expectedHeaders: const ExpectHeaders({'X-Client-Id'}),
            ),
          ],
        );

        final response = await send('data', method: 'OPTIONS');
        expect(response.statusCode, HttpStatus.forbidden);
      });
    });
  });
}
