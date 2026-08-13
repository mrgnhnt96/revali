import 'package:revali_core/health/health_check.dart';

/// Liveness and readiness probes.
///
/// The two answer different questions, and conflating them is the usual way a
/// deploy goes wrong:
///
/// - **Liveness** — "is this process wedged?" A failure means *restart me*.
/// - **Readiness** — "should traffic come here?" A failure means *route
///   elsewhere*, and the process is left alone.
///
/// That difference is why liveness keeps returning 200 during a graceful
/// shutdown while readiness flips to 503. Failing liveness mid-drain would
/// have the orchestrator kill the pod, truncating exactly the in-flight
/// requests the drain exists to protect.
///
/// Probes are served **outside** the app's [prefix], because orchestrators are
/// configured with bare paths and a probe should not inherit an application
/// routing concern.
///
/// [prefix]: AppConfig.prefix
class HealthSettings {
  const HealthSettings({
    this.livenessPath = '/healthz',
    this.readinessPath = '/readyz',
    this.checks = const [],
    this.checkTimeout = const Duration(seconds: 5),
  });

  /// Serves no probes at all.
  const HealthSettings.disabled()
      : livenessPath = null,
        readinessPath = null,
        checks = const [],
        checkTimeout = Duration.zero;

  /// Where liveness is served. `null` disables it.
  ///
  /// This endpoint runs no [checks] — it answers only that the process is
  /// alive and its event loop is turning. Consulting a database here is a
  /// well-known way to turn one database blip into a full restart storm.
  final String? livenessPath;

  /// Where readiness is served. `null` disables it.
  final String? readinessPath;

  /// Dependencies consulted by the readiness probe.
  ///
  /// All are run concurrently; any failure makes the whole probe unhealthy.
  final List<HealthCheck> checks;

  /// How long a single check may take before it counts as unhealthy.
  ///
  /// Keep this below the orchestrator's own probe timeout, or the probe is
  /// cut off before the check can report which dependency was slow.
  final Duration checkTimeout;

  /// Whether any probe is served.
  bool get enabled => livenessPath != null || readinessPath != null;
}
