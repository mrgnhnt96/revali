import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../.revali/server/server.dart';
import '../routes/apps/test_app.dart';

/// The one link in the per-isolate-identity chain that unit tests cannot reach.
///
/// The generator emitting the right code, `IsolateIdentity` not being inherited
/// across a spawn, and `RedisBroker` suffixing a name from an identity are all
/// covered elsewhere. What none of them covers is that a worker isolate the
/// *generated server* spawned actually receives index `i` at runtime and
/// publishes it before `createBroker()` runs. Every one of those tests fakes
/// the identity with `setCurrentForGeneratedCode`, so all of them would still
/// pass if the boot payload dropped the index and every worker named itself 0.
///
/// Reaching the worker path requires `createServer(null, ...)`: the generated
/// spawn is gated on `providedServer == null`
/// (`packages/revali/lib/server/makers/server_file_maker.dart`), so no
/// `TestServer`-based test can ever get there. That means a real socket and
/// real isolates, which is why this package exists rather than another case in
/// an existing one.
void main() {
  test('every spawned worker isolate observes its own index', () async {
    final directory = IsolateReport.directory;
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
    directory.createSync(recursive: true);

    // No provided server: this is the only call shape that spawns workers.
    final server = await createServer();
    addTearDown(() => server.close(force: true));

    final reports = await _awaitReports(
      directory,
      expected: TestApp.workerCount,
    );

    // Assert on the *set*, not the count: a fleet that numbered itself
    // `0, 0, 0` still produces three reports, and that is precisely the bug.
    expect(
      reports.map((r) => r.index).toSet(),
      {for (var i = 0; i < TestApp.workerCount; i++) i},
      reason: 'indices should be exactly 0..${TestApp.workerCount - 1}',
    );

    // ...and on the count too, so a fleet that reported `{0, 1, 2}` from four
    // isolates, or from one, is not quietly accepted by the set check.
    expect(reports, hasLength(TestApp.workerCount));

    expect(
      reports.map((r) => r.workerCount).toSet(),
      {TestApp.workerCount},
      reason: 'every isolate should see the same configured fleet size',
    );

    // The point of the index is that something keying on a name can tell the
    // isolates apart. Derived the way `RedisBroker` derives its consumer name,
    // without depending on `revali_redis` — the naming rule is unit-tested
    // there; what is unproven is that the index feeding it differs at all.
    expect(
      reports.map((r) => 'worker-${r.index}').toSet(),
      hasLength(TestApp.workerCount),
    );
  });
}

class _Report {
  const _Report({required this.index, required this.workerCount});

  final int index;
  final int workerCount;
}

/// Polls until [expected] reports have landed, or gives up.
///
/// Polling rather than a fixed sleep: isolate spawn plus a socket bind is not
/// a bounded wait on a loaded machine, and a sleep long enough to be safe there
/// is a slow test everywhere else. The deadline only decides how long a
/// *broken* run takes to fail, and is kept well under `package:test`'s own 30s
/// timeout so a failure arrives as the assertion below rather than as an
/// anonymous `TimeoutException` that says nothing about what went wrong.
///
/// It keeps reading for a beat after reaching [expected], so a fleet that
/// produced too many reports fails the count assertion rather than racing past
/// it on the first [expected] it sees.
Future<List<_Report>> _awaitReports(
  Directory directory, {
  required int expected,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));

  var settled = false;
  while (DateTime.now().isBefore(deadline)) {
    final reports = _readReports(directory);
    if (reports.length >= expected) {
      if (settled) return reports;
      settled = true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  return _readReports(directory);
}

/// Every `report.json` under [directory], one per isolate that reported.
List<_Report> _readReports(Directory directory) {
  if (!directory.existsSync()) return const [];

  return [
    for (final entity in directory.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('report.json'))
        if (_read(entity) case final contents when contents.isNotEmpty)
          if (jsonDecode(contents) case final Map<String, dynamic> json)
            _Report(
              index: json['index'] as int,
              workerCount: json['workerCount'] as int,
            ),
  ];
}

/// An isolate may be mid-write while the poll reads; a file that is not there
/// or not readable yet this tick simply is not a report yet.
String _read(File file) {
  try {
    return file.readAsStringSync();
  } on FileSystemException {
    return '';
  }
}
