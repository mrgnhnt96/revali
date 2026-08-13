import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_core/revali_core.dart';

/// Rejects callers that exceed [max] requests per [window] with `429`.
///
/// Apply on an app, controller, or endpoint:
///
/// ```dart
/// @Throttle(max: 100, window: Duration(minutes: 1))
/// @Controller('search')
/// class SearchController { ... }
/// ```
///
/// Counting is per **caller** and per **bucket**. The caller is the client IP
/// (resolved through `AppConfig.trustedProxy`, so a proxied deployment counts
/// the real client rather than the proxy). The bucket defaults to the matched
/// route's registered path — `/api/users/:id`, not `/api/users/42` — so every
/// caller gets one allowance for the endpoint rather than one per id.
///
/// Set [bucket] to share an allowance across several endpoints:
///
/// ```dart
/// @Throttle(max: 10, window: Duration(minutes: 1), bucket: 'auth')
/// ```
///
/// This is a fixed window, kept in memory. Two consequences worth knowing
/// before relying on it:
///
/// - A caller can send up to `2 * max` across a window boundary, which is
///   inherent to fixed windows. Set [max] with that in mind.
/// - State is per isolate and per process. With `AppConfig.workers > 1`, or
///   more than one instance behind a load balancer, each has its own counters
///   and the effective limit multiplies. For a shared limit, put it in front
///   of the server, or back it with an external store such as Redis.
final class Throttle implements LifecycleComponent {
  const Throttle({
    this.max = 60,
    this.window = const Duration(minutes: 1),
    this.bucket,
  }) : assert(max > 0, 'max must be greater than 0');

  /// Requests allowed per [window].
  final int max;

  /// How long an allowance lasts.
  final Duration window;

  /// Groups callers into a shared allowance. Defaults to the matched route.
  final String? bucket;

  /// Counters, keyed by `bucket|caller`.
  static final Map<String, _Window> _windows = {};

  /// Stops the map growing without bound when callers are many and
  /// short-lived. Swept on write, so there is no timer to leak.
  static const _sweepEvery = 512;
  static int _writesSinceSweep = 0;

  /// Clears all counters. For tests — production has no reason to.
  static void reset() {
    _windows.clear();
    _writesSinceSweep = 0;
  }

  GuardResult limit(Context context) {
    final caller = context.request.ip ?? 'unknown';
    final key = '${bucket ?? context.route.fullPath}|$caller';
    final now = DateTime.now();

    _sweep(now);

    final current = _windows[key];
    if (current == null || !current.contains(now)) {
      _windows[key] = _Window(expiresAt: now.add(window), count: 1);

      return const GuardResult.pass();
    }

    current.count++;

    if (current.count <= max) {
      return const GuardResult.pass();
    }

    final retryAfter = current.expiresAt.difference(now);

    return GuardResult.block(
      statusCode: 429,
      headers: {
        // Whole seconds, and never 0 -- a client told to retry immediately
        // would just be blocked again.
        'retry-after': '${retryAfter.inSeconds.clamp(1, 1 << 31)}',
        'x-ratelimit-limit': '$max',
        'x-ratelimit-remaining': '0',
      },
      body: 'Too Many Requests',
    );
  }

  void _sweep(DateTime now) {
    if (++_writesSinceSweep < _sweepEvery) {
      return;
    }
    _writesSinceSweep = 0;

    _windows.removeWhere((_, window) => !window.contains(now));
  }
}

class _Window {
  _Window({required this.expiresAt, required this.count});

  final DateTime expiresAt;
  int count;

  bool contains(DateTime now) => now.isBefore(expiresAt);
}
