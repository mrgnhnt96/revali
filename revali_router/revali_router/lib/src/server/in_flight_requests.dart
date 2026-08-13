import 'dart:async';

/// Tracks requests that are still being served, so a shutdown can wait for
/// them instead of dropping them mid-response.
///
/// The accept loop detaches each request so a slow handler cannot stall
/// `accept()`. That means nothing otherwise holds a reference to the work in
/// progress, and closing the server truncates whatever was still writing.
class InFlightRequests {
  final _active = <Future<void>>{};

  var _draining = false;

  /// Whether [drain] has been called and no further work should be accepted.
  bool get isDraining => _draining;

  /// How many requests are currently being served.
  int get length => _active.length;

  bool get isEmpty => _active.isEmpty;

  /// Registers [work] as in-flight until it completes.
  ///
  /// Errors are swallowed here — callers already report and respond to their
  /// own failures, and a rejected future must not make [drain] give up on the
  /// requests that are still healthy.
  void track(Future<void> work) {
    final tracked = work.catchError((Object _) {});

    _active.add(tracked);
    tracked.whenComplete(() => _active.remove(tracked));
  }

  /// Marks a shutdown as under way.
  ///
  /// Called before the server stops accepting, so the accept loop can tell
  /// "we are draining" from "the listener died" and leave teardown to the
  /// shutdown path instead of tearing down under the requests still running.
  void beginDraining() => _draining = true;

  /// Waits for in-flight requests to finish, up to [timeout].
  ///
  /// Returns true if everything completed, false if the timeout struck first
  /// and requests were still running.
  Future<bool> drain(Duration timeout) async {
    _draining = true;

    if (_active.isEmpty) {
      return true;
    }

    try {
      await Future.wait(_active.toList()).timeout(timeout);

      return true;
    } on TimeoutException {
      return false;
    }
  }
}
