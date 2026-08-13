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
