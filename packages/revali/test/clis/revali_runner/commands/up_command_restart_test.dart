import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/up_command.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

/// `revali up` starting a service whose process is gone.
///
/// The gap `r` cannot close. Reload travels by writing a service's
/// `.revali_cmd`, which the running `revali dev` is watching — so it works
/// while the wrapper is alive with a dead server inside it (`needs fix`), and
/// does nothing at all once the wrapper itself has exited (`crashed`,
/// `stopped`). Nothing is left to read the file. The only way back is another
/// `Process.start`, which is what [UpCommand.restart] does.
///
/// Every process here is a fake: the suite must not spawn real
/// `dart run revali dev` children on the machine running it, and the spawner
/// seam exists so it does not have to.
void main() {
  late MemoryFileSystem fs;
  late _Spawner spawner;
  late UpCommand command;

  setUp(() {
    fs = MemoryFileSystem.test();
    spawner = _Spawner();
    command = UpCommand(logger: Logger(), fs: fs, spawn: spawner.call)
      // A session per service, which is what the TUI path has and what a
      // restart acts on. Without it there are no panes and no `s` key.
      ..useTui = true;
  });

  ServicePlan planFor(String name, {int port = 8080}) {
    final directory = fs.directory('/repo/$name')..createSync(recursive: true);

    return ServicePlan(
      service: RevaliService(
        name: name,
        directory: directory,
        relativePath: name,
      ),
      port: port,
      label: name,
    );
  }

  /// Lets every pending exit callback and notification run.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('restarting a dead service', () {
    test('spawns a fresh process for it', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      expect(await command.startFleet(plans, sessions), isTrue);
      expect(spawner.workingDirectories, ['/repo/billing', '/repo/orders']);

      spawner.processes[0].die(1);
      await settle();
      expect(sessions[0].state, ServiceState.crashed);

      await command.restart(sessions[0], plans);

      expect(
        spawner.workingDirectories,
        ['/repo/billing', '/repo/orders', '/repo/billing'],
        reason: "a third spawn, in the dead service's own directory",
      );
      expect(
        spawner.calls.last.arguments,
        ['run', 'revali', 'dev'],
        reason: 'the same command the first start used',
      );
      expect(
        spawner.calls.last.environment?['PORT'],
        '8080',
        reason: 'the port the fleet assigned does not move across a restart',
      );
    });

    test('replaces the dead entry rather than leaving it behind', () async {
      // Two services, because a fleet of one that dies is a run that is over —
      // see the last group in this file.
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);
      final first = spawner.processes.first..die(1);
      await settle();

      await command.restart(sessions[0], plans);
      final second = spawner.processes.last;

      expect(identical(first, second), isFalse);

      // `Ctrl+C` has to reach the *live* child. If the dead one were still the
      // process behind this label, the new one would be holding the port with
      // nothing left able to signal it.
      command.buildApp(plans, sessions).onQuit();

      expect(second.killed, isTrue);
    });

    test('empties the pane and unfreezes the scroll', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);
      final session = sessions.first;

      spawner.processes.first
        ..emit('Serving at http://0.0.0.0:8080/\n')
        ..emit('Unhandled exception: everything is on fire\n', isError: true)
        ..die(1);
      await settle();

      // Scrolled back to read why it died, which is the ordinary thing to do
      // just before reaching for the start key.
      session.scrollBy(-1, viewport: 1);
      expect(session.lines, isNotEmpty);
      expect(session.isLive, isFalse);

      await command.restart(session, plans);

      expect(
        session.lines,
        isEmpty,
        reason:
            'the old output is readable right up to the restart, and the '
            'restart is the act that lets it go',
      );
      expect(
        session.isLive,
        isTrue,
        reason: 'a fresh buffer under a kept scroll anchor draws blank',
      );
      expect(session.state, ServiceState.starting);
      expect(session.exitCode, isNull);
    });

    test('lets the new process move the state again', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);
      final session = sessions.first;

      spawner.processes.first.die(1);
      await settle();
      expect(session.state, ServiceState.crashed);

      await command.restart(session, plans);

      spawner.processes.last.emit('Serving at http://0.0.0.0:8080/\n');
      await settle();

      expect(
        session.state,
        ServiceState.serving,
        reason:
            'a session that still believed it had exited would ignore '
            'every frame the new process sent it',
      );
    });
  });

  group('restarting declines', () {
    test('at a service that is still running', () async {
      final plans = [planFor('billing')];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);

      await command.restart(sessions.single, plans);

      expect(
        spawner.calls,
        hasLength(1),
        reason:
            'a second process would take the first one out of reach of '
            'Ctrl+C and leave it sitting on the port',
      );
    });

    test('at a service that only needs a fix', () async {
      final plans = [planFor('billing')];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);
      final session = sessions.single;

      // `revali dev` is alive; the server inside it could not get its socket.
      spawner.processes.single.emit(
        '[WARN] Failed to bind server: port in use\n'
        'Dev server is still running\n',
        isError: true,
      );
      await settle();
      expect(session.state, ServiceState.failed);

      await command.restart(session, plans);

      expect(
        spawner.calls,
        hasLength(1),
        reason:
            'the wrapper is still watching .revali_cmd, so `r` is what '
            'this state wants and there is nothing to start',
      );
    });

    test('once the fleet is draining', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);

      spawner.processes[0].die(1);
      await settle();
      expect(sessions[0].state, ServiceState.crashed);

      // `Ctrl+C`. Every remaining child has had its SIGTERM.
      command.buildApp(plans, sessions).onQuit();

      await command.restart(sessions[0], plans);

      expect(
        spawner.calls,
        hasLength(2),
        reason:
            'starting a service into a shutdown would leave a child that '
            'nothing has signalled and nothing is waiting for',
      );
    });

    test('for a session no plan answers to', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);
      spawner.processes.first.die(1);
      await settle();

      final stranger = ServiceSession(planFor('ghost', port: 9999))
        ..markExited(1);

      await command.restart(stranger, plans);

      expect(spawner.calls, hasLength(2));
    });

    test('once the whole fleet has gone, because the run is over', () async {
      final plans = [planFor('billing')];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);

      spawner.processes.single.die(1);
      await settle();

      expect(sessions.single.state, ServiceState.crashed);
      await expectLater(command.fleetGone, completes);

      await command.restart(sessions.single, plans);

      expect(
        spawner.calls,
        hasLength(1),
        reason:
            'the boundary `s` has, and it is deliberate: reaching this key '
            'means focusing a service, which means a screen, which means '
            'another service still holding it up. A fleet that is entirely '
            'gone ends the run rather than sitting on an empty screen.',
      );
    });
  });

  group('the fleet is gone', () {
    test('only once the restarted service has gone too', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      await command.startFleet(plans, sessions);
      expect(command.aliveCount, 2);

      var gone = false;
      unawaited(command.fleetGone.then((_) => gone = true));

      spawner.processes[0].die(1);
      await settle();
      expect(command.aliveCount, 1);
      expect(gone, isFalse);

      await command.restart(sessions[0], plans);
      expect(
        command.aliveCount,
        2,
        reason: 'a service that was brought back is running again',
      );

      // Both of the ORIGINAL processes are now accounted for. This is the
      // moment the old `Future.wait(exits)` completed: it iterated the list
      // once, when it was called, so the exit future the restart appended was
      // never waited on and the screen came down over a live service.
      spawner.processes[1].die(0);
      await settle();

      expect(
        gone,
        isFalse,
        reason:
            'the restarted service is still running, so the fleet is not '
            'gone and the screen must stay up',
      );
      expect(command.aliveCount, 1);

      spawner.processes[2].die(1);
      await settle();

      expect(
        gone,
        isTrue,
        reason:
            'now there really is nothing left, and a screen that never '
            'came down would be the other half of this bug',
      );
    });

    test('is not declared while the fleet is still being started', () async {
      final plans = [
        planFor('billing'),
        planFor('orders', port: 8081),
        planFor('users', port: 8082),
      ];
      final sessions = <ServiceSession>[];

      var gone = false;
      unawaited(command.fleetGone.then((_) => gone = true));

      // The first service dies on the spot, while the others are still being
      // spawned — so the running count passes through zero legitimately.
      spawner.onSpawn = (process, index) {
        if (index == 0) process.die(1);
      };

      await command.startFleet(plans, sessions);
      await settle();

      expect(gone, isFalse);
      expect(command.aliveCount, 2);
    });

    test('is declared when every service dies while starting', () async {
      final plans = [planFor('billing'), planFor('orders', port: 8081)];
      final sessions = <ServiceSession>[];

      var gone = false;
      unawaited(command.fleetGone.then((_) => gone = true));

      spawner.onSpawn = (process, _) => process.die(1);

      expect(await command.startFleet(plans, sessions), isTrue);
      await settle();

      expect(
        gone,
        isTrue,
        reason:
            'there is no exit left to come and notice it, so the check '
            'after the starting loop is the only one that can',
      );
    });
  });
}

/// One recorded call to the spawner.
typedef _Call = ({
  String executable,
  List<String> arguments,
  String? workingDirectory,
  Map<String, String>? environment,
});

/// A stand-in for `Process.start` that records what it was asked for and hands
/// back a process the test drives by hand.
class _Spawner {
  final calls = <_Call>[];
  final processes = <_FakeProcess>[];

  /// Run on each new process, so a test can arrange for one to die during the
  /// starting loop rather than after it.
  void Function(_FakeProcess process, int index)? onSpawn;

  List<String?> get workingDirectories =>
      calls.map((call) => call.workingDirectory).toList();

  Future<io.Process> call(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    calls.add((
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    ));

    final process = _FakeProcess();
    processes.add(process);
    onSpawn?.call(process, processes.length - 1);

    return process;
  }
}

/// A child that never existed: its output and its exit are whatever the test
/// says they are.
class _FakeProcess implements io.Process {
  final _exit = Completer<int>();
  final _out = StreamController<List<int>>();
  final _err = StreamController<List<int>>();

  /// Whether [kill] reached it — which is how a test tells the live child from
  /// the dead one it replaced.
  bool killed = false;

  void emit(String text, {bool isError = false}) {
    (isError ? _err : _out).add(utf8.encode(text));
  }

  void die(int code) {
    if (_exit.isCompleted) return;

    _out.close().ignore();
    _err.close().ignore();
    _exit.complete(code);
  }

  @override
  Future<int> get exitCode => _exit.future;

  @override
  Stream<List<int>> get stdout => _out.stream;

  @override
  Stream<List<int>> get stderr => _err.stream;

  @override
  io.IOSink get stdin => throw UnsupportedError('the child reads no stdin');

  @override
  int get pid => 4242;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    killed = true;

    return true;
  }
}
