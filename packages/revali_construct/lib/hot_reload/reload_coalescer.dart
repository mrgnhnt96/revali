/// Serializes hot-reload server restarts.
///
/// At most one restart runs at a time. If another restart is requested while
/// one is active, a single pending restart is kept. Additional requests while
/// that pending restart is already queued replace it rather than enqueueing
/// more work.
class CoalescingReloadQueue {
  CoalescingReloadQueue(this._run);

  final Future<void> Function() _run;

  Future<void>? _active;
  bool _pending = false;

  /// Schedules a restart.
  ///
  /// Returns a future that completes after this request's restart cycle
  /// finishes, including any coalesced pending restart triggered while it
  /// was running.
  Future<void> schedule() {
    if (_active case final active?) {
      _pending = true;
      return active;
    }

    return _active = _drain();
  }

  Future<void> _drain() async {
    try {
      do {
        _pending = false;
        await _run();
      } while (_pending);
    } finally {
      _active = null;
    }
  }
}
