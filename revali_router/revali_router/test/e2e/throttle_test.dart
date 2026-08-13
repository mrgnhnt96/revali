import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

void main() {
  group('Throttle', () {
    late HttpServer server;
    late HttpClient client;

    Future<void> serve(Throttle limit, {String path = 'ping'}) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

      final router = Router(
        routes: [
          Route(
            path,
            method: 'GET',
            guards: [_KitGuard(limit)],
            handler: (context) async {
              context.response.body = 'pong';
            },
          ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));
    }

    Future<int> hit([String path = 'ping']) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/$path'),
      );
      final response = await request.close();
      await response.drain<void>();

      return response.statusCode;
    }

    setUp(() {
      Throttle.reset();
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
      Throttle.reset();
    });

    test('allows up to the limit then blocks with 429', () async {
      await serve(const Throttle(max: 3));

      expect(await hit(), 200);
      expect(await hit(), 200);
      expect(await hit(), 200);
      expect(await hit(), 429, reason: 'the fourth exceeds max: 3');
    });

    test('the block carries Retry-After and limit headers', () async {
      await serve(const Throttle(max: 1, window: Duration(seconds: 30)));

      await hit();

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}/ping'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 429);
      expect(response.headers.value('x-ratelimit-limit'), '1');
      expect(response.headers.value('x-ratelimit-remaining'), '0');
      expect(body, contains('Too Many Requests'));

      // Never 0: a client told to retry immediately is just blocked again.
      final retryAfter = int.parse(response.headers.value('retry-after')!);
      expect(retryAfter, greaterThan(0));
      expect(retryAfter, lessThanOrEqualTo(30));
    });

    test('the allowance comes back after the window', () async {
      await serve(const Throttle(max: 1, window: Duration(milliseconds: 150)));

      expect(await hit(), 200);
      expect(await hit(), 429);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(await hit(), 200, reason: 'window expired');
    });

    test('separate routes get separate allowances', () async {
      // Two routes, one limiter config: the default bucket is the matched
      // route, so exhausting one must not block the other.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      const limit = Throttle(max: 1);

      final router = Router(
        routes: [
          for (final path in ['alpha', 'beta'])
            Route(
              path,
              method: 'GET',
              guards: const [_KitGuard(limit)],
              handler: (context) async {
                context.response.body = path;
              },
            ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));

      expect(await hit('alpha'), 200);
      expect(await hit('alpha'), 429);
      expect(await hit('beta'), 200, reason: 'a different bucket');
    });

    test('a shared bucket pools the allowance across routes', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      const limit = Throttle(max: 1, bucket: 'shared');

      final router = Router(
        routes: [
          for (final path in ['alpha', 'beta'])
            Route(
              path,
              method: 'GET',
              guards: const [_KitGuard(limit)],
              handler: (context) async {
                context.response.body = path;
              },
            ),
        ],
      );

      unawaited(handleRouterRequests(server, router, server.close));

      expect(await hit('alpha'), 200);
      expect(await hit('beta'), 429, reason: 'same bucket as alpha');
    });

    test('rejects a non-positive max at construction', () {
      expect(() => Throttle(max: 0), throwsA(isA<AssertionError>()));
    });
  });
}

/// Mirrors what the generator emits for a `GuardResult`-returning kit method,
/// so the kit is exercised through the real guard pipeline.
class _KitGuard implements Guard {
  const _KitGuard(this.limit);

  final Throttle limit;

  @override
  Future<GuardResult> protect(Context context) async => limit.limit(context);
}
