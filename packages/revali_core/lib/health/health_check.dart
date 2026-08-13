import 'dart:async';

/// The outcome of a single [HealthCheck].
class HealthCheckResult {
  const HealthCheckResult.healthy([this.detail]) : isHealthy = true;

  const HealthCheckResult.unhealthy([this.detail]) : isHealthy = false;

  /// Whether the dependency this check covers is usable.
  final bool isHealthy;

  /// Optional human-facing context, surfaced in the probe body.
  ///
  /// Keep it descriptive rather than sensitive — a readiness endpoint is
  /// typically reachable by anything that can reach the pod, so a connection
  /// string or a credential does not belong here.
  final String? detail;
}

/// One dependency a readiness probe consults.
///
/// A check answers "can this service do its job right now", which is not the
/// same question as "is this process alive". Reach for it when the service
/// cannot usefully serve traffic without the dependency — a primary database,
/// a required upstream. A cache that the service degrades gracefully without
/// should *not* be a readiness check, or one slow cache node pulls the whole
/// service out of rotation.
///
/// ```dart
/// class DatabaseIsReachable implements HealthCheck {
///   const DatabaseIsReachable(this.db);
///
///   final Database db;
///
///   @override
///   String get name => 'database';
///
///   @override
///   Future<HealthCheckResult> check() async {
///     try {
///       await db.ping();
///       return const HealthCheckResult.healthy();
///     } catch (e) {
///       return HealthCheckResult.unhealthy('$e');
///     }
///   }
/// }
/// ```
///
/// A check that throws is treated as unhealthy rather than allowed to reach
/// the response — a probe that 500s tells the orchestrator far less than one
/// that reports which dependency is down.
abstract interface class HealthCheck {
  const HealthCheck();

  /// Identifies this check in the probe body. Keep it stable; it is a label.
  String get name;

  FutureOr<HealthCheckResult> check();
}
