import 'dart:async';
import 'dart:io';

import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/route/route.dart';

/// Builds the liveness and readiness routes described by [settings].
///
/// These are registered outside the app's prefix, next to the `public` routes,
/// so they answer on the bare paths an orchestrator is configured with.
///
/// [isDraining] is read on every readiness request rather than captured, so
/// the probe reflects the *current* shutdown state instead of the state at
/// startup.
List<Route> healthRoutes({
  required HealthSettings settings,
  required bool Function() isDraining,
}) {
  if (!settings.enabled) {
    return const [];
  }

  return [
    if (settings.livenessPath case final path?)
      Route(
        _normalize(path),
        method: 'GET',
        ignorePathPattern: true,
        handler: (context) async {
          // Deliberately 200 even mid-drain. Liveness failing tells the
          // orchestrator to *restart* the process, which would kill the
          // in-flight requests the drain is there to finish.
          context.response.statusCode = HttpStatus.ok;
          context.response.body = {'status': 'ok'};
        },
      ),
    if (settings.readinessPath case final path?)
      Route(
        _normalize(path),
        method: 'GET',
        ignorePathPattern: true,
        handler: (context) async {
          if (isDraining()) {
            context.response.statusCode = HttpStatus.serviceUnavailable;
            context.response.body = {'status': 'draining'};

            return;
          }

          final results = await _runChecks(settings);
          final ready = results.values.every((r) => r.isHealthy);

          context.response.statusCode =
              ready ? HttpStatus.ok : HttpStatus.serviceUnavailable;

          context.response.body = {
            'status': ready ? 'ok' : 'unhealthy',
            if (results.isNotEmpty)
              'checks': {
                for (final MapEntry(key: name, value: result)
                    in results.entries)
                  name: {
                    'status': result.isHealthy ? 'ok' : 'unhealthy',
                    if (result.detail case final detail?) 'detail': detail,
                  },
              },
          };
        },
      ),
  ];
}

/// Runs every check concurrently, so the probe costs the slowest check rather
/// than the sum of all of them.
Future<Map<String, HealthCheckResult>> _runChecks(
  HealthSettings settings,
) async {
  if (settings.checks.isEmpty) {
    return const {};
  }

  final results = await Future.wait([
    for (final check in settings.checks) _runOne(check, settings.checkTimeout),
  ]);

  return {
    for (final (index, result) in results.indexed)
      settings.checks[index].name: result,
  };
}

/// Never throws: a check that fails, hangs, or blows up is reported as
/// unhealthy. A probe that 500s tells the orchestrator strictly less than one
/// that names the dependency which is down.
Future<HealthCheckResult> _runOne(HealthCheck check, Duration timeout) async {
  try {
    final result = Future.value(check.check());

    if (timeout > Duration.zero) {
      return await result.timeout(
        timeout,
        onTimeout: () => HealthCheckResult.unhealthy(
          'timed out after ${timeout.inMilliseconds}ms',
        ),
      );
    }

    return await result;
  } catch (e) {
    return HealthCheckResult.unhealthy('$e');
  }
}

/// Routes are registered without a leading slash, but probe paths are written
/// the way they are configured in an orchestrator — `/healthz`.
String _normalize(String path) {
  var normalized = path;

  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }

  return normalized;
}
