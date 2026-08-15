import 'dart:io';

import 'package:revali_router/revali_router.dart';

/// Where each isolate of the fleet writes the identity it actually observed.
///
/// **Why a file and not a static list.** Isolates share no memory: a static in
/// the test process can never see what a worker isolate wrote. That is not an
/// inconvenience to work around, it is the exact property this test exists to
/// prove — the index has to survive the boot payload into a fresh heap. So the
/// workers report out of band, and the filesystem is the least machinery that
/// works.
///
/// **Why the path needs no plumbing.** Every isolate computes [directory]
/// independently and has to arrive at the same string. `Platform.environment`
/// is a property of the *process*, and spawned isolates live in the same
/// process, so an env var reaches them for free — no boot-payload slot, and
/// nothing this test could accidentally prove by passing the answer in
/// alongside the thing under test. The `systemTemp` fallback keeps the package
/// runnable with `dart test` and no setup at all.
abstract final class IsolateReport {
  /// Overridable so two checkouts on one machine do not share a report dir.
  static Directory get directory => Directory(
    Platform.environment['REVALI_WORKERS_E2E_DIR'] ??
        '${Directory.systemTemp.path}/revali_workers_e2e',
  );

  /// A concrete, high, unlikely port.
  ///
  /// Port `0` is not an option here: with `workers > 1` every isolate binds
  /// the *same* port with `shared: true`, and `0` would hand each isolate its
  /// own ephemeral port instead of a shared one — which is a different app
  /// than the one under test. The env var is the escape hatch for a machine
  /// where the default is taken.
  static int get port =>
      int.tryParse(Platform.environment['REVALI_WORKERS_E2E_PORT'] ?? '') ??
      58231;

  /// Records [identity], called from inside [TestApp.createBroker].
  ///
  /// The call site matters: `createBroker()` is where the original bug bit,
  /// and it is the one place the ordering guarantee has to hold — the
  /// generated server publishes the identity *before* `runStartup`, and a
  /// broker naming itself from `IsolateIdentity.current` reads it in here.
  ///
  /// **One file per isolate, named by the OS and not by the index.** Naming
  /// the file after the reported index is the obvious thing and it is wrong
  /// twice over. It lets the bug hide — three isolates that all believed they
  /// were `0` would produce one file, the same shape a healthy single-worker
  /// fleet produces — and it makes the isolates contend for one path, where
  /// concurrent appends were observed to clobber each other outright. A
  /// `createTempSync` name is unique by construction, so a broken fleet leaves
  /// three files that each say `0`: the failure, stated rather than collapsed.
  static void record(IsolateIdentity identity) {
    directory.createSync(recursive: true);

    final slot = directory.createTempSync('report-');
    File('${slot.path}/report.json').writeAsStringSync(
      '{"index":${identity.index},"workerCount":${identity.workerCount}}',
      flush: true,
    );
  }
}

@App(flavor: 'test')
final class TestApp extends AppConfig {
  /// Not `const`: [IsolateReport.port] is read from the environment at
  /// runtime, so neither this constructor nor the generated call to it can be.
  TestApp()
    : super(
        host: '127.0.0.1',
        port: IsolateReport.port,
        workers: workerCount,
      );

  /// Above 1, or the generated server spawns nothing and the test is vacuous.
  /// Three rather than two, so a fleet that numbers itself `0, 1, 1` fails.
  static const workerCount = 3;

  /// The test process is not a server being orchestrated, and installing
  /// process-wide signal handlers from it would outlive the test.
  @override
  bool get handleShutdownSignals => false;

  @override
  Future<MessageBroker?> createBroker() async {
    IsolateReport.record(IsolateIdentity.current);

    // No broker: this package is about which isolate we are, not about
    // messaging. A `@Consumes` handler exists only so the generated server
    // calls this method at all.
    return null;
  }

  @override
  void onServerStarted(HttpServer server) {}
}
