import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

const _origin = 'https://app.example.com';
const _preflight = {
  'origin': _origin,
  'access-control-request-method': 'GET',
};

class _PublicPolicy extends CorsPolicy {
  const _PublicPolicy();

  @override
  CorsGrant grant(String? origin) {
    return (allowOrigin: '*', allowCredentials: false);
  }
}

class _RecordingPolicy extends CorsPolicy {
  final seen = <String?>[];

  @override
  CorsGrant grant(String? origin) {
    seen.add(origin);
    return super.grant(origin);
  }
}

class _ThrowingPolicy extends CorsPolicy {
  const _ThrowingPolicy();

  @override
  CorsGrant grant(String? origin) => throw StateError('no policy');
}

String? _header(Response response, String name) {
  return response.headers.values[name]?.join(', ');
}

Future<void> _ok(Context context) async {
  context.response.statusCode = HttpStatus.ok;
}

void main() {
  group(CorsPolicy, () {
    group('by default', () {
      requestTest(
        'reflects the origin with credentials',
        TestRoute(handler: _ok, headers: const {'origin': _origin}),
        verifyResponse: (response, _) {
          expect(_header(response, 'access-control-allow-origin'), _origin);
          expect(_header(response, 'access-control-allow-credentials'), 'true');
        },
      );

      requestTest(
        'does the same on a preflight',
        TestRoute(
          handler: _ok,
          requestMethod: 'OPTIONS',
          headers: _preflight,
        ),
        verifyResponse: (response, _) {
          expect(_header(response, 'access-control-allow-origin'), _origin);
          expect(_header(response, 'access-control-allow-credentials'), 'true');
        },
      );

      requestTest(
        'answers * with credentials when no Origin was sent',
        TestRoute(handler: _ok),
        verifyResponse: (response, _) {
          expect(_header(response, 'access-control-allow-origin'), '*');
          expect(_header(response, 'access-control-allow-credentials'), 'true');
        },
      );
    });

    group('with a policy granting * without credentials', () {
      requestTest(
        'applies to a preflight',
        TestRoute(
          handler: _ok,
          cors: const _PublicPolicy(),
          requestMethod: 'OPTIONS',
          headers: _preflight,
        ),
        verifyResponse: (response, _) {
          expect(response.statusCode, HttpStatus.ok);
          expect(_header(response, 'access-control-allow-origin'), '*');
          expect(_header(response, 'access-control-allow-credentials'), isNull);
        },
      );

      requestTest(
        'applies to a real response',
        TestRoute(
          handler: _ok,
          cors: const _PublicPolicy(),
          headers: const {'origin': _origin},
        ),
        verifyResponse: (response, _) {
          expect(response.statusCode, HttpStatus.ok);
          expect(_header(response, 'access-control-allow-origin'), '*');
          expect(_header(response, 'access-control-allow-credentials'), isNull);
        },
      );
    });

    test('is asked with the origin, or null when none was sent', () async {
      final policy = _RecordingPolicy();

      await testRequest(
        TestRoute(
          handler: _ok,
          cors: policy,
          headers: const {'origin': _origin},
        ),
        verifyResponse: (_, __) {},
      );
      await testRequest(
        TestRoute(handler: _ok, cors: policy),
        verifyResponse: (_, __) {},
      );

      expect(policy.seen, [_origin, null]);
    });

    test('is not asked about an origin @AllowOrigins refuses', () async {
      final policy = _RecordingPolicy();

      await testRequest(
        TestRoute(
          handler: _ok,
          cors: policy,
          allowedOrigins: const AllowOrigins({'https://other.example.com'}),
          headers: const {'origin': _origin},
        ),
        verifyResponse: (response, _) {
          expect(response.statusCode, HttpStatus.forbidden);
        },
      );

      expect(policy.seen, isEmpty);
    });

    requestTest(
      'grants nothing when the policy throws',
      TestRoute(
        handler: _ok,
        cors: const _ThrowingPolicy(),
        headers: const {'origin': _origin},
      ),
      verifyResponse: (response, _) {
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(_header(response, 'access-control-allow-origin'), isNull);
        expect(_header(response, 'access-control-allow-credentials'), isNull);
      },
    );
  });

  group('Vary: Origin', () {
    requestTest(
      'is on a real response',
      TestRoute(handler: _ok, headers: const {'origin': _origin}),
      verifyResponse: (response, _) {
        expect(_header(response, 'vary'), 'Origin');
      },
    );

    requestTest(
      'is on a preflight',
      TestRoute(handler: _ok, requestMethod: 'OPTIONS', headers: _preflight),
      verifyResponse: (response, _) {
        expect(_header(response, 'vary'), 'Origin');
      },
    );

    requestTest(
      'is on a response whose grant does not depend on the origin',
      TestRoute(
        handler: _ok,
        cors: const _PublicPolicy(),
        headers: const {'origin': _origin},
      ),
      verifyResponse: (response, _) {
        expect(_header(response, 'vary'), 'Origin');
      },
    );

    requestTest(
      'is absent when no Origin was sent',
      TestRoute(handler: _ok),
      verifyResponse: (response, _) {
        expect(_header(response, 'vary'), isNull);
      },
    );

    requestTest(
      'is on a refused origin, so a cached 403 cannot reach an admitted one',
      TestRoute(
        handler: _ok,
        allowedOrigins: const AllowOrigins({'https://other.example.com'}),
        headers: const {'origin': _origin},
      ),
      verifyResponse: (response, _) {
        expect(response.statusCode, HttpStatus.forbidden);
        expect(_header(response, 'vary'), 'Origin');
      },
    );

    requestTest(
      'is on a refusal over a missing header',
      TestRoute(
        handler: _ok,
        expectedHeaders: const ExpectHeaders({'x-client-id'}),
        headers: const {'origin': _origin},
      ),
      verifyResponse: (response, _) {
        expect(response.statusCode, HttpStatus.forbidden);
        expect(_header(response, 'vary'), 'Origin');
      },
    );

    test('joins what an app-supplied refusal already varies on, once',
        () async {
      final refusal = SimpleResponse(
        HttpStatus.forbidden,
        headers: const {'vary': 'accept-language'},
      );

      for (var i = 0; i < 2; i++) {
        await testRequest(
          TestRoute(
            handler: _ok,
            allowedOrigins: const AllowOrigins({'https://other.example.com'}),
            defaultResponses: DefaultResponses(failedCorsOrigin: refusal),
            headers: const {'origin': _origin},
          ),
          verifyResponse: (response, _) {
            expect(_header(response, 'vary'), 'accept-language, Origin');
          },
        );
      }
    });
  });

  group('over a real connection', () {
    late HttpServer server;
    late HttpClient client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = HttpClient()..autoUncompress = false;

      final router = Router(
        cors: const _PublicPolicy(),
        routes: [
          Route(
            'data',
            method: 'GET',
            handler: (context) async {
              context.response
                ..headers.mimeType = 'application/json'
                ..body = jsonEncode(List.filled(500, 'item'));
            },
          ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    Future<HttpClientResponse> send(String method) async {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:${server.port}/data'),
      );
      request.headers
        ..set('origin', _origin)
        ..set('access-control-request-method', 'GET')
        ..set(HttpHeaders.acceptEncodingHeader, 'gzip');

      final response = await request.close();
      await response.drain<void>();

      return response;
    }

    test('a preflight carries the grant', () async {
      final response = await send('OPTIONS');

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.value('access-control-allow-origin'), '*');
      expect(response.headers.value('access-control-allow-credentials'), null);
      expect(response.headers.value('vary'), 'Origin');
    });

    test('a compressed response varies on both', () async {
      final response = await send('GET');

      expect(response.headers.value('content-encoding'), 'gzip');
      expect(response.headers.value('access-control-allow-origin'), '*');
      expect(response.headers.value('access-control-allow-credentials'), null);
      expect(response.headers.value('vary'), 'Origin, accept-encoding');
    });
  });
}
