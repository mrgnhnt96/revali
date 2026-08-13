import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

/// When a failed request is worth sending again.
///
/// Off by default ([RetryPolicy.none]), because retrying is not universally
/// safe and the client cannot tell on its own which calls tolerate it.
///
/// Two rules keep the default honest:
///
/// - **Only idempotent methods.** Retrying a `POST` that actually reached the
///   server and failed on the way back creates the resource twice. `GET`,
///   `HEAD`, `OPTIONS`, `PUT` and `DELETE` are defined as idempotent by HTTP;
///   `POST` and `PATCH` are not.
/// - **Only transient statuses.** `502`, `503` and `504` say the far side was
///   temporarily unable to answer. A `400` or a `404` will say exactly the
///   same thing next time, and retrying it just multiplies load during an
///   incident.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 10),
    this.retryableStatusCodes = const {502, 503, 504},
    this.idempotentMethods = const {
      'GET',
      'HEAD',
      'OPTIONS',
      'PUT',
      'DELETE',
    },
    this.retryOnConnectionErrors = true,
    this.honorRetryAfter = true,
  }) : assert(maxAttempts >= 1, 'maxAttempts must be >= 1');

  /// Never retries. The default.
  const RetryPolicy.none()
    : maxAttempts = 1,
      initialDelay = Duration.zero,
      maxDelay = Duration.zero,
      retryableStatusCodes = const {},
      idempotentMethods = const {},
      retryOnConnectionErrors = false,
      honorRetryAfter = false;

  /// Total attempts, the first one included. `3` means one try and two
  /// retries.
  final int maxAttempts;

  /// Delay before the second attempt; doubles each time, capped at [maxDelay].
  final Duration initialDelay;

  final Duration maxDelay;

  /// Statuses worth sending again.
  final Set<int> retryableStatusCodes;

  /// Methods safe to send more than once.
  final Set<String> idempotentMethods;

  /// Whether a transport failure — connection refused, reset, timed out —
  /// is retried.
  ///
  /// Note this includes requests that may have reached the server, which is
  /// why it is still gated on [idempotentMethods].
  final bool retryOnConnectionErrors;

  /// Whether a `Retry-After` header overrides the computed backoff.
  ///
  /// Only the delta-seconds form is honoured. The HTTP-date form is ignored in
  /// favour of the backoff, rather than guessed at against a clock that may
  /// not agree with the server's.
  final bool honorRetryAfter;

  bool get enabled => maxAttempts > 1;

  /// Whether [request] may be sent more than once at all.
  ///
  /// A streamed body is consumed as it is sent, so a second attempt would
  /// transmit nothing — the request has to be refused for retry regardless of
  /// method.
  bool allows(HttpRequest request) {
    if (!enabled || request.bodyStream != null) {
      return false;
    }

    return idempotentMethods.contains(request.method.toUpperCase());
  }

  /// Whether a response that arrived should be thrown away and retried.
  bool shouldRetryResponse(HttpResponse response, int attempt) {
    if (attempt >= maxAttempts) {
      return false;
    }

    return retryableStatusCodes.contains(response.statusCode);
  }

  /// Whether a transport failure should be retried.
  bool shouldRetryError(int attempt) {
    if (attempt >= maxAttempts) {
      return false;
    }

    return retryOnConnectionErrors;
  }

  /// How long to wait before attempt number [attempt] + 1.
  ///
  /// Exponential from [initialDelay], capped at [maxDelay]. [response] is
  /// consulted for `Retry-After` when [honorRetryAfter] is set: a server that
  /// says when it will be ready knows better than a fixed curve.
  Duration delayFor(int attempt, [HttpResponse? response]) {
    if (honorRetryAfter && response != null) {
      if (retryAfterOf(response) case final delay?) {
        return delay;
      }
    }

    final micros = initialDelay.inMicroseconds * (1 << (attempt - 1));

    return micros >= maxDelay.inMicroseconds
        ? maxDelay
        : Duration(microseconds: micros);
  }

  /// The `Retry-After` delay, when the header carries the delta-seconds form.
  static Duration? retryAfterOf(HttpResponse response) {
    final header = response.headers['retry-after'];
    if (header == null) {
      return null;
    }

    final seconds = int.tryParse(header.trim());
    if (seconds == null || seconds < 0) {
      return null;
    }

    return Duration(seconds: seconds);
  }
}
