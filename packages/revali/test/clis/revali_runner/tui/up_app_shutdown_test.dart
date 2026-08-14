import 'package:file/memory.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:revali/clis/revali_runner/tui/shutdown_view.dart';
import 'package:revali/clis/revali_runner/tui/up_app.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fs;

  setUp(() => fs = MemoryFileSystem());

  ServiceSession session(String name, int port) {
    fs.directory('/repo/$name').createSync(recursive: true);

    return ServiceSession(
      ServicePlan(
        service: RevaliService(
          name: name,
          directory: fs.directory('/repo/$name'),
          relativePath: name,
        ),
        port: port,
        label: name,
      ),
    );
  }

  /// What the runner does with a `Ctrl+C`, in the shape `UpCommand._quit` does
  /// it: the first press stops the fleet, and any press after that stops
  /// waiting for it. Modelled here rather than counted as bare callbacks so a
  /// test can say *which* of the two branches a press reached — the second one
  /// is the escape hatch for a child that ignores SIGTERM, and a counter that
  /// only says "2" would pass just as happily if both presses stopped the
  /// fleet again.
  late int stops;
  late int stopsWaiting;

  void quit() {
    if (stops > 0) {
      stopsWaiting++;

      return;
    }

    stops++;
  }

  late List<(String name, String command)> commands;
  late List<String> fleetCommands;

  setUp(() {
    stops = 0;
    stopsWaiting = 0;
    commands = [];
    fleetCommands = [];
  });

  Future<NoctermTester> pumpApp(
    List<ServiceSession> sessions, {
    Size size = const Size(80, 24),
  }) async {
    final tester = await NoctermTester.create(size: size);
    addTearDown(tester.dispose);

    await tester.pumpComponent(
      UpApp(
        sessions: sessions,
        onCommand: (session, command) => commands.add((session.name, command)),
        onCommandAll: fleetCommands.add,
        onQuit: quit,
      ),
    );

    return tester;
  }

  /// `Ctrl+C` as a terminal delivers it.
  const ctrlC = KeyboardEvent(
    logicalKey: LogicalKey.keyC,
    modifiers: ModifierKeys(ctrl: true),
  );

  /// A shifted letter as a terminal delivers it: the same logical key as the
  /// unshifted one, carrying the uppercase character.
  KeyboardEvent shifted(LogicalKey key, String character) => KeyboardEvent(
    logicalKey: key,
    character: character,
    modifiers: const ModifierKeys(shift: true),
  );

  group('the swap', () {
    test('ctrl+C replaces the whole screen, not a line of it', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final tester = await pumpApp([billing]);

      // The running screen, before.
      expect(tester.terminalState, containsText('r reload'));
      expect(tester.terminalState, containsText('Serving at http://0.0.0.0'));

      await tester.sendKeyEvent(ctrlC);

      expect(tester.terminalState, containsText(kShutdownMessage));

      // And what it replaced is gone. A screen that kept offering `r reload`
      // beside "cleaning up" would still be advertising a key that no longer
      // does anything.
      expect(tester.terminalState, isNot(containsText('r reload')));
      expect(tester.terminalState, isNot(containsText('R/C/Q all')));
      expect(
        tester.terminalState,
        isNot(containsText('Serving at http://0.0.0.0')),
      );
    });

    test('it says the fleet is being cleaned up, in words', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      await tester.sendKeyEvent(ctrlC);

      expect(tester.terminalState, containsText('Cleaning up resources'));
      expect(tester.terminalState, containsText('this will take but a moment'));
    });

    test('the frame and its title survive the swap', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      await tester.sendKeyEvent(ctrlC);

      expect(
        tester.terminalState,
        containsText('revali up'),
        reason: 'the shutdown screen is the same window, not a new program',
      );
    });

    test(
      'the first press stops the fleet rather than stopping waiting',
      () async {
        final tester = await pumpApp([session('billing', 8080)]);

        await tester.sendKeyEvent(ctrlC);

        expect(stops, 1);
        expect(stopsWaiting, 0);
      },
    );

    test(
      'an empty fleet still gets the message rather than throwing',
      () async {
        final tester = await pumpApp([]);

        await tester.sendKeyEvent(ctrlC);

        expect(tester.terminalState, containsText(kShutdownMessage));
        expect(tester.terminalState, isNot(containsText('No services.')));
      },
    );
  });

  group('the per-service rows', () {
    test('every service is still named after the swap', () async {
      final tester = await pumpApp([
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKeyEvent(ctrlC);

      expect(tester.terminalState, containsText('billing'));
      expect(tester.terminalState, containsText('orders'));
    });

    test('a running service reads as draining', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final tester = await pumpApp([billing]);

      await tester.sendKeyEvent(ctrlC);

      expect(billing.state, ServiceState.serving);
      expect(tester.terminalState, containsText('billing'));
      expect(tester.terminalState, containsText(kDrainingLabel));
    });

    test('a row keeps updating as its service actually goes down', () async {
      // The requirement the whole screen rests on: a caption over a frozen
      // list is the same hang it was before, with a caption.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);
      final orders = session('orders', 8081)
        ..ingest('Serving at http://0.0.0.0:8081/api\n', isError: false);

      final tester = await pumpApp([billing, orders]);

      await tester.sendKeyEvent(ctrlC);

      expect(tester.terminalState, containsText(kDrainingLabel));
      expect(tester.terminalState, isNot(containsText('stopped')));

      // The child exits, exactly as it does under a real SIGTERM.
      billing.markExited(0);
      await tester.pump();

      expect(tester.terminalState, containsText('stopped'));
      expect(
        tester.terminalState,
        containsText(kDrainingLabel),
        reason: 'orders has not gone yet, and its row must still say so',
      );

      orders.markExited(0);
      await tester.pump();

      expect(
        tester.terminalState,
        isNot(containsText(kDrainingLabel)),
        reason: 'nothing is draining once every child is gone',
      );
    });

    test('a crashed service is not labelled draining', () async {
      // It exited before the signal was ever sent. Calling it "draining" would
      // claim `revali up` is waiting on it, and would bury the compile error
      // that is most likely why the developer is quitting.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);
      final orders = session('orders', 8081)
        ..ingest('Error: no such method\n', isError: true)
        ..markExited(1);

      final tester = await pumpApp([billing, orders]);

      await tester.sendKeyEvent(ctrlC);

      expect(orders.state, ServiceState.crashed);
      expect(tester.terminalState, containsText('crashed'));
      expect(
        shutdownStateLabel(orders.state),
        isNot(kDrainingLabel),
        reason: 'a crashed service is already down',
      );

      // The one that is genuinely going down still says so, so the assertion
      // above is not passing because nothing anywhere reads as draining.
      expect(shutdownStateLabel(billing.state), kDrainingLabel);
    });

    test('a service that needs fixing is not labelled draining', () async {
      final orders = session('orders', 8081)
        ..ingest(
          'Failed to bind server: address already in use\n',
          isError: true,
        );

      final tester = await pumpApp([orders]);

      await tester.sendKeyEvent(ctrlC);

      expect(orders.state, ServiceState.failed);
      expect(tester.terminalState, containsText('needs fix'));
      expect(tester.terminalState, isNot(containsText(kDrainingLabel)));
    });
  });

  group('the second press', () {
    test(
      'reaches the stop-waiting branch rather than stopping again',
      () async {
        final tester = await pumpApp([session('billing', 8080)]);

        await tester.sendKeyEvent(ctrlC);
        await tester.sendKeyEvent(ctrlC);

        expect(stops, 1, reason: 'the fleet is stopped once');
        expect(stopsWaiting, 1, reason: 'the second press is the way out');
      },
    );

    test('the screen says the escape hatch is there', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      await tester.sendKeyEvent(ctrlC);

      expect(tester.terminalState, containsText(kShutdownEscapeHint));
      expect(tester.terminalState, containsText('^C again'));
    });
  });

  group('the keys that are no longer live', () {
    test('r, c and q do nothing once the fleet is draining', () async {
      final tester = await pumpApp([
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKeyEvent(ctrlC);

      await tester.sendKey(LogicalKey.keyR);
      await tester.sendKey(LogicalKey.keyC);
      await tester.sendKey(LogicalKey.keyQ);
      await tester.sendKeyEvent(shifted(LogicalKey.keyR, 'R'));
      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.digit2);

      expect(
        commands,
        isEmpty,
        reason: 'a reload written to a service that is exiting is a lie',
      );
      expect(fleetCommands, isEmpty);

      // And the screen did not quietly go back to the running one.
      expect(tester.terminalState, containsText(kShutdownMessage));
    });
  });

  group('shift+Q', () {
    test('swaps to the shutdown screen too, as it stops the fleet', () async {
      // `UpCommand.buildApp` calls `_stop()` for a fleet-wide quit, so this is
      // the same drain as a `Ctrl+C` and the same screen has to explain it.
      final tester = await pumpApp([session('billing', 8080)]);

      await tester.sendKeyEvent(shifted(LogicalKey.keyQ, 'Q'));

      expect(fleetCommands, [UpCommand.quit]);
      expect(tester.terminalState, containsText(kShutdownMessage));
    });

    test('an unshifted q leaves the running screen alone', () async {
      // It stops one service; the rest of the fleet carries on and there is
      // nothing to explain.
      final tester = await pumpApp([
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKey(LogicalKey.keyQ);

      expect(commands, [('billing', UpCommand.quit)]);
      expect(tester.terminalState, isNot(containsText(kShutdownMessage)));
      expect(tester.terminalState, containsText('r reload'));
    });

    test('shift+R and shift+C are untouched', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      await tester.sendKeyEvent(shifted(LogicalKey.keyR, 'R'));
      await tester.sendKeyEvent(shifted(LogicalKey.keyC, 'C'));

      expect(fleetCommands, [UpCommand.reload, UpCommand.clear]);
      expect(tester.terminalState, isNot(containsText(kShutdownMessage)));
    });
  });
}
