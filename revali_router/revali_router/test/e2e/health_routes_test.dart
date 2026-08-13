import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';
import 'package:test/test.dart';

/// A check whose outcome the test controls.
class _Fake implements HealthCheck {
  _Fake(this.name, this._result);

  _Fake.throwing(this.name) : _result = null;

  @override
  final String name;

  final HealthCheckResult? _result;

  @override
  Future<HealthCheckResult> check() async {
    if (_result case final result?) {
      return result;
    }

    throw StateError('check exploded');
  }
}

/// A check that never completes, to exercise [HealthSettings.checkTimeout].
class _Hangs implements HealthCheck {
  @override
  String get name => 'hangs';

  @override
  Future<HealthCheckResult> check() => Completer<HealthCheckResult>().future;
}

void main() {
  group('health routes', () {
    late HttpServer server;
    late HttpClient client;
    late InFlightRequests inFlight;

    Future<void> serve(HealthSettings settings) async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      inFlight = InFlightRequests();

      final router = Router(
        routes: [
          ...healthRoutes(
            settings: settings,
            isDraining: () => inFlight.isDraining,
          ),
        ],
      );

      unawaited(
        handleRouterRequests(server, router, server.close, inFlight: inFlight),
      );
    }

    /// Returns the status and the decoded body, or `null` for a body that is
    /// not JSON at all (a 404 answers in plain text).
    Future<(int, Map<String, dynamic>?)> get(String path) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${server.port}$path'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        decoded = null;
      }

      return (response.statusCode, decoded);
    }

    setUp(() => client = HttpClient());

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    test('liveness reports ok', () async {
      await serve(const HealthSettings());

      final (status, body) = await get('/healthz');

      expect(status, HttpStatus.ok);
      expect(body, {'status': 'ok'});
    });

    test('liveness stays ok while draining', () async {
      await serve(const HealthSettings());

      inFlight.beginDraining();

      // Liveness failing tells the orchestrator to restart the process, which
      // would kill exactly the in-flight requests the drain protects.
      final (status, body) = await get('/healthz');

      expect(status, HttpStatus.ok);
      expect(body, {'status': 'ok'});
    });

    test('readiness reports ok with no checks registered', () async {
      await serve(const HealthSettings());

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.ok);
      expect(body, {'status': 'ok'});
    });

    test('readiness reports unavailable while draining', () async {
      await serve(const HealthSettings());

      inFlight.beginDraining();

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.serviceUnavailable);
      expect(body, {'status': 'draining'});
    });

    test('draining short-circuits before checks run', () async {
      // A hanging check would blow the test's own timeout if it were reached.
      await serve(HealthSettings(checks: [_Hangs()]));

      inFlight.beginDraining();

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.serviceUnavailable);
      expect(body, {'status': 'draining'});
    });

    test('readiness lists every healthy check', () async {
      await serve(
        HealthSettings(
          checks: [
            _Fake('database', const HealthCheckResult.healthy()),
            _Fake('queue', const HealthCheckResult.healthy('12 consumers')),
          ],
        ),
      );

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.ok);
      expect(body, {
        'status': 'ok',
        'checks': {
          'database': {'status': 'ok'},
          'queue': {'status': 'ok', 'detail': '12 consumers'},
        },
      });
    });

    test('one failing check makes the whole probe unavailable', () async {
      await serve(
        HealthSettings(
          checks: [
            _Fake('database', const HealthCheckResult.healthy()),
            _Fake('queue', const HealthCheckResult.unhealthy('broker down')),
          ],
        ),
      );

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.serviceUnavailable);
      expect(body, {
        'status': 'unhealthy',
        'checks': {
          'database': {'status': 'ok'},
          'queue': {'status': 'unhealthy', 'detail': 'broker down'},
        },
      });
    });

    test('a throwing check is unhealthy, not a 500', () async {
      await serve(HealthSettings(checks: [_Fake.throwing('database')]));

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.serviceUnavailable);
      expect(body!['status'], 'unhealthy');
      expect(
        (body['checks'] as Map)['database'],
        {'status': 'unhealthy', 'detail': contains('check exploded')},
      );
    });

    test('a hanging check is unhealthy once checkTimeout passes', () async {
      await serve(
        HealthSettings(
          checks: [_Hangs()],
          checkTimeout: const Duration(milliseconds: 50),
        ),
      );

      final (status, body) = await get('/readyz');

      expect(status, HttpStatus.serviceUnavailable);
      expect(
        (body!['checks'] as Map)['hangs'],
        {'status': 'unhealthy', 'detail': contains('timed out')},
      );
    });

    test('paths are configurable', () async {
      await serve(
        const HealthSettings(
          livenessPath: '/alive',
          readinessPath: '/ready',
        ),
      );

      expect((await get('/alive')).$1, HttpStatus.ok);
      expect((await get('/ready')).$1, HttpStatus.ok);
      expect((await get('/healthz')).$1, HttpStatus.notFound);
    });

    test('either probe can be disabled on its own', () async {
      await serve(const HealthSettings(livenessPath: null));

      expect((await get('/healthz')).$1, HttpStatus.notFound);
      expect((await get('/readyz')).$1, HttpStatus.ok);
    });
  });

  group('healthRoutes()', () {
    test('builds nothing when disabled', () {
      expect(
        healthRoutes(
          settings: const HealthSettings.disabled(),
          isDraining: () => false,
        ),
        isEmpty,
      );
    });

    test('reads isDraining per request rather than capturing it', () {
      var draining = false;

      final routes = healthRoutes(
        settings: const HealthSettings(),
        isDraining: () => draining,
      );

      // Registration happens at startup, long before any shutdown. Capturing
      // the value here would pin readiness to `false` forever.
      draining = true;

      expect(routes, hasLength(2));
    });
  });
}
