import 'dart:async';

import 'package:revali_core/components/request_listener.dart';

/// What a completed request looked like, from the outside.
///
/// The shape a metrics counter, a latency histogram or a tracing span needs:
/// enough to label the measurement, and nothing that pins the request's
/// objects in memory after it has finished.
class RequestSummary {
  const RequestSummary({
    required this.method,
    required this.path,
    required this.routePath,
    required this.statusCode,
    required this.duration,
    required this.startedAt,
    this.error,
  });

  final String method;

  /// The concrete path this request asked for, e.g. `/api/users/42`.
  final String path;

  /// The **registered** path of the route that matched, e.g.
  /// `/api/users/:id`, or null when nothing matched.
  ///
  /// This is the one to label metrics with. Using [path] instead gives every
  /// id its own time series, which is how a metrics backend falls over.
  final String? routePath;

  final int statusCode;

  final Duration duration;

  final DateTime startedAt;

  /// Set when the response carried an error body.
  final String? error;
}

/// Receives a summary of every request once it completes.
///
/// Separate from `Observer` on purpose. `Observer` sees a request as it
/// begins and is handed the response as a future; this fires after the fact
/// with the timing already resolved, which is what exporting a metric or
/// closing a span actually needs.
///
/// Registered like any other observer, and implementing `Observer` as well is
/// optional — the router dispatches on whichever interfaces are present:
///
/// ```dart
/// class Metrics implements RequestObserver {
///   const Metrics();
///
///   @override
///   void onRequestComplete(RequestSummary summary) {
///     requestCount.labels(summary.routePath ?? 'unmatched').inc();
///     latency.observe(summary.duration.inMilliseconds);
///   }
/// }
/// ```
///
/// ```dart
/// @Observers([Metrics])
/// @App()
/// final class MyApp extends AppConfig { ... }
/// ```
///
/// Called on the response path, so keep it cheap — buffer and flush
/// elsewhere rather than awaiting a network write here. Errors thrown from it
/// are swallowed: the response has already been produced, and a broken
/// metrics exporter must not take the request with it.
abstract interface class RequestObserver implements RequestListener {
  const RequestObserver();

  FutureOr<void> onRequestComplete(RequestSummary summary);
}
