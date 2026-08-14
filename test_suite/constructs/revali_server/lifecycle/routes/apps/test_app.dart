import 'dart:io';

import 'package:revali_router/revali_router.dart';

/// A readiness dependency the tests can take down.
class DatabaseProbe implements HealthCheck {
  const DatabaseProbe();

  /// Flipped by tests to prove readiness actually consults its checks.
  static bool healthy = true;

  @override
  String get name => 'database';

  @override
  HealthCheckResult check() {
    return healthy
        ? const HealthCheckResult.healthy('connected')
        : const HealthCheckResult.unhealthy('connection refused');
  }
}

/// Deliberately **not** `const`: `AppConfig.fromEnv` reads the environment at
/// runtime, so an app using it cannot be const either. Generated code has to
/// instantiate it accordingly, which is the regression this fixture guards.
@App(flavor: 'test')
final class TestApp extends AppConfig {
  TestApp() : super.fromEnv(defaultPort: 0);

  @override
  HealthSettings get health => const HealthSettings(checks: [DatabaseProbe()]);

  @override
  void onServerStarted(HttpServer server) {}
}
