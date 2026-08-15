/// Which isolate of the app this code is running in.
///
/// An app with `AppConfig.workers` greater than 1 runs the same program in
/// several isolates. They are identical by construction, which is the point —
/// and also the problem, because some things an app talks to identify their
/// clients *by name*. A message broker that tracks unacknowledged work per
/// consumer name will hand every worker the same name, and each worker's
/// pending messages become invisible to the others. Telling the isolates apart
/// requires knowing which one you are.
///
/// **Statics in Dart are per-isolate.** Each isolate gets its own copy of
/// top-level and static state — nothing is shared, and there is no race to
/// guard against. That is not a caveat, it is the whole mechanism: a static
/// *can* describe "which isolate am I" precisely because every isolate has a
/// different one. It is the same reason the private `_revaliIsWorker` flag in
/// the generated server file works.
///
/// Read it from anywhere, including code that has no way to be handed
/// configuration — an `AppConfig.createBroker` override, for instance, takes
/// no arguments.
///
/// The common use is work that must happen once for the *process* rather than
/// once per isolate:
///
/// ```dart
/// @override
/// Future<void> configureDependencies(DI di) async {
///   if (!IsolateIdentity.current.isWorker) {
///     di.registerSingleton<NightlyReport>(NightlyReport()..start());
///   }
/// }
/// ```
///
/// Note that `RedisBroker` names its own consumers from this — appending
/// [index] to the name it was given — so an app does *not* have to work the
/// index into `consumerName` itself. Doing so anyway produces `orders-1-1`.
///
/// Unset, it describes the parent of a single-isolate app: index `0`, not a
/// worker, one isolate in total. So a unit test, a `dart test` run, or an app
/// that never spawns workers observes something true without configuring
/// anything, and there is no null to handle.
class IsolateIdentity {
  const IsolateIdentity({
    required this.index,
    required this.workerCount,
  })  : assert(index >= 0, 'index must be >= 0'),
        assert(workerCount >= 1, 'workerCount must be >= 1'),
        assert(index < workerCount, 'index must be < workerCount');

  /// The parent isolate of an app that runs in one isolate.
  static const IsolateIdentity single = IsolateIdentity(
    index: 0,
    workerCount: 1,
  );

  /// Position in the fleet: `0` is the parent, `1..workerCount - 1` a worker.
  ///
  /// Stable for the life of the isolate, and unique across the fleet, which is
  /// what makes it usable as the distinguishing part of a name that some
  /// external system keys on.
  final int index;

  /// How many isolates the app was configured for — `AppConfig.workers`.
  ///
  /// `1` when the app runs single-isolate. Every isolate reports the same
  /// value, including the parent, so `index` and `workerCount` together
  /// describe the whole fleet from inside any member of it.
  final int workerCount;

  /// Whether this is a spawned worker rather than the parent.
  ///
  /// Derived from [index] rather than stored, so the two cannot disagree.
  bool get isWorker => index > 0;

  /// The identity of the isolate this code is running in.
  static IsolateIdentity get current => _current;

  static IsolateIdentity _current = single;

  /// Framework plumbing — called by generated code, not by app authors.
  ///
  /// The generated server file calls this once per isolate, before anything
  /// the app wrote gets to run. Calling it from application code means lying
  /// about which isolate you are in, and whatever reads [current] to name
  /// itself will believe you.
  ///
  /// Deliberately a method rather than a settable `current`: the name is the
  /// warning, and `IsolateIdentity.current = ...` would read like something an
  /// app is meant to do.
  // ignore: use_setters_to_change_properties
  static void setCurrentForGeneratedCode(IsolateIdentity identity) {
    _current = identity;
  }

  @override
  String toString() =>
      'IsolateIdentity(index: $index, workerCount: $workerCount)';
}
