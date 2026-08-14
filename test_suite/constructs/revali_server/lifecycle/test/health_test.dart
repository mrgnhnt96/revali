import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';
import '../routes/apps/test_app.dart';

void main() {
  group('health probes on a generated server', () {
    late TestServer server;

    setUp(() async {
      DatabaseProbe.healthy = true;
      server = TestServer();
      await createServer(server);
    });

    tearDown(() => server.close());

    test('liveness answers outside the app prefix', () async {
      // Orchestrators are configured with bare paths; if the generated server
      // ever registers these inside the prefix wrapping, this breaks.
      final response = await server.send(method: 'GET', path: '/healthz');

      expect(response.statusCode, 200);
      expect(response.body, {'status': 'ok'});
    });

    test('liveness is not served under the prefix', () async {
      final response = await server.send(method: 'GET', path: '/api/healthz');

      expect(response.statusCode, 404);
    });

    test('readiness reports ok while its checks pass', () async {
      final response = await server.send(method: 'GET', path: '/readyz');

      expect(response.statusCode, 200);
      expect(response.body, {
        'status': 'ok',
        'checks': {
          'database': {'status': 'ok', 'detail': 'connected'},
        },
      });
    });

    test('readiness consults AppConfig.health checks', () async {
      DatabaseProbe.healthy = false;

      final response = await server.send(method: 'GET', path: '/readyz');

      // Proves the checks declared on AppConfig actually reached the router
      // through code generation, not just that a probe route exists.
      expect(response.statusCode, 503);
      expect(response.body, {
        'status': 'unhealthy',
        'checks': {
          'database': {'status': 'unhealthy', 'detail': 'connection refused'},
        },
      });
    });

    test('probes are not wrapped in the data envelope', () async {
      final response = await server.send(method: 'GET', path: '/healthz');

      // Ordinary handlers return {"data": ...}; a probe body an orchestrator
      // reads should not be.
      expect((response.body as Map).containsKey('data'), isFalse);
    });

    test('ordinary routes still carry the data envelope', () async {
      final response = await server.send(
        method: 'GET',
        path: '/api/lifecycle/trace',
      );

      expect((response.body as Map).containsKey('data'), isTrue);
    });
  });
}
