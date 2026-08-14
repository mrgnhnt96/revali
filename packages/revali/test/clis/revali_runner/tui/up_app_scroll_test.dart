import 'package:file/memory.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:revali/clis/revali_runner/tui/up_app.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

/// The focused pane's scrollback.
///
/// The pair these tests exist for is [stick and unstick][1]: output arriving
/// while the pane is at the live end must move it, and output arriving while
/// the pane is scrolled up must not. Either one alone is satisfied by a pane
/// that always tails, which is what this used to be — so both are asserted
/// side by side, and both were checked to fail against the old always-tail
/// pane before the new one was written.
///
/// [1]: ServiceSession.scrollTop
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

  /// Feeds [count] numbered lines, so a test can name the exact line it
  /// expects to be on screen rather than counting rows.
  void fill(ServiceSession target, int count, {int from = 0}) {
    for (var i = from; i < from + count; i++) {
      target.ingest('line-$i\n', isError: false);
    }
  }

  Future<NoctermTester> pumpApp(
    List<ServiceSession> sessions, {
    Size size = const Size(80, 24),
  }) async {
    final tester = await NoctermTester.create(size: size);
    addTearDown(tester.dispose);

    await tester.pumpComponent(
      UpApp(
        sessions: sessions,
        onCommand: (session, command) {
          // The runner writes the key through to the child, which clears its
          // own screen and sends the sequence back. Standing in for that here
          // keeps the test about the pane rather than about a process.
          if (command == UpCommand.clear) {
            session.ingest('\x1b[2J', isError: false);
          }
        },
        onCommandAll: (_) {},
        onQuit: () {},
      ),
    );

    return tester;
  }

  /// A wheel notch over the row at [y].
  MouseEvent wheel(MouseButton button, {required int y, int x = 10}) =>
      MouseEvent(button: button, pressed: true, x: x, y: y);

  group('scrolling reaches what the tail dropped', () {
    test('k shows a line that had scrolled off the top', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      // The pane is nowhere near 60 rows tall, so the early lines are gone.
      expect(tester.terminalState, containsText('line-59'));
      expect(tester.terminalState, isNot(containsText('line-40')));

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }

      expect(tester.terminalState, containsText('line-40'));
    });

    test('PageUp reaches further back than k does in one press', () async {
      final billing = session('billing', 8080);
      fill(billing, 200);

      final tester = await pumpApp([billing]);

      await tester.sendKey(LogicalKey.keyK);
      final afterLine = _topLineNumber(tester);

      await tester.sendKey(LogicalKey.pageUp);
      final afterPage = _topLineNumber(tester);

      expect(
        afterPage,
        lessThan(afterLine),
        reason: 'a page must move further back than a single line',
      );
    });

    test('scrolling stops at the oldest line still kept', () async {
      // The cap is the scrollback depth: there is nothing behind it to reach.
      final billing = session('billing', 8080)
        ..ingest('oldest\n', isError: false);
      fill(billing, 40);

      final tester = await pumpApp([billing]);

      for (var i = 0; i < 200; i++) {
        await tester.sendKey(LogicalKey.pageUp);
      }

      expect(tester.terminalState, containsText('oldest'));
    });
  });

  group('stick and unstick', () {
    test('at the live end, new output moves the view', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);
      expect(tester.terminalState, containsText('line-59'));

      fill(billing, 1, from: 60);
      await tester.pump();

      expect(
        tester.terminalState,
        containsText('line-60'),
        reason: 'a pane at the live end follows what its service prints',
      );
    });

    test('scrolled up, new output does NOT move the view', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }

      expect(tester.terminalState, containsText('line-40'));
      final before = _topLineNumber(tester);

      // The noisy case `revali up` is built for: another service printing
      // while this one is being read.
      fill(billing, 30, from: 60);
      await tester.pump();

      expect(
        _topLineNumber(tester),
        before,
        reason: 'output must not yank a pane the user is reading',
      );
      expect(tester.terminalState, containsText('line-40'));
      expect(tester.terminalState, isNot(containsText('line-89')));
    });

    test('scrolling back down to the newest line re-sticks', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      await tester.sendKey(LogicalKey.keyK);
      expect(tester.terminalState, containsText('more'));

      // Far more than enough to land back on the end.
      for (var i = 0; i < 40; i++) {
        await tester.sendKey(LogicalKey.keyJ);
      }

      expect(tester.terminalState, isNot(containsText('more')));

      fill(billing, 1, from: 60);
      await tester.pump();

      expect(
        tester.terminalState,
        containsText('line-60'),
        reason: 'reaching the end again must resume following it',
      );
    });
  });

  group('the way back to the live end', () {
    test('g returns to the newest line and re-sticks', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }
      expect(tester.terminalState, isNot(containsText('line-59')));

      await tester.sendKey(LogicalKey.keyG);

      expect(tester.terminalState, containsText('line-59'));

      fill(billing, 1, from: 60);
      await tester.pump();

      expect(
        tester.terminalState,
        containsText('line-60'),
        reason: 'g must resume following, not just jump once',
      );
    });
  });

  group('the not-at-live indicator', () {
    test('is absent while the pane is following', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      // `↓` alone is not a sentinel — the legend's `↑↓ select` carries one.
      expect(tester.terminalState, isNot(containsText('more')));
    });

    test('appears with a count once scrolled up', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      for (var i = 0; i < 5; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }

      expect(tester.terminalState, containsText('↓ 5 more'));
      expect(tester.terminalState, containsText('g live'));
    });

    test('counts up as output arrives behind a frozen pane', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      await tester.sendKey(LogicalKey.keyK);
      expect(tester.terminalState, containsText('↓ 1 more'));

      fill(billing, 4, from: 60);
      await tester.pump();

      expect(
        tester.terminalState,
        containsText('↓ 5 more'),
        reason: 'a frozen pane says how far behind it has fallen',
      );
    });

    test('goes away again on g', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      await tester.sendKey(LogicalKey.keyK);
      expect(tester.terminalState, containsText('more'));

      await tester.sendKey(LogicalKey.keyG);
      expect(tester.terminalState, isNot(containsText('more')));
    });
  });

  group('the wheel', () {
    test('scrolls the pane it is over', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);
      expect(tester.terminalState, containsText('line-59'));

      // Row 10 is inside the log pane: the roster and its rules take the top
      // few rows of an 80x24 screen.
      await tester.sendMouseEvent(wheel(MouseButton.wheelUp, y: 10));

      expect(tester.terminalState, containsText('more'));
      expect(tester.terminalState, isNot(containsText('line-59')));
    });

    test('a notch down brings it back toward the live end', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      await tester.sendMouseEvent(wheel(MouseButton.wheelUp, y: 10));
      final scrolled = _topLineNumber(tester);

      await tester.sendMouseEvent(wheel(MouseButton.wheelDown, y: 10));

      expect(_topLineNumber(tester), greaterThan(scrolled));
    });

    test('over the roster it leaves the log alone', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);
      final before = _topLineNumber(tester);

      // Row 1 is the roster, above the log pane's region.
      await tester.sendMouseEvent(wheel(MouseButton.wheelUp, y: 1));

      expect(_topLineNumber(tester), before);
      expect(
        tester.terminalState,
        isNot(containsText('more')),
        reason: 'a wheel over the roster must not freeze the log pane',
      );
    });
  });

  group('each service keeps its own position', () {
    test('switching away and back lands where it was left', () async {
      final billing = session('billing', 8080);
      final orders = session('orders', 8081);
      fill(billing, 60);
      fill(orders, 60);

      final tester = await pumpApp([billing, orders]);

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }
      final parked = _topLineNumber(tester);
      expect(tester.terminalState, containsText('↓ 12 more'));

      // Glance at the other service — which has never been scrolled, so it is
      // at its own live end.
      await tester.sendKey(LogicalKey.arrowDown);
      expect(tester.terminalState, containsText('line-59'));
      expect(tester.terminalState, isNot(containsText('more')));

      await tester.sendKey(LogicalKey.arrowUp);

      expect(_topLineNumber(tester), parked);
      expect(tester.terminalState, containsText('↓ 12 more'));
    });

    test('output for the other service does not disturb a parked pane',
        () async {
      final billing = session('billing', 8080);
      final orders = session('orders', 8081);
      fill(billing, 60);
      fill(orders, 60);

      final tester = await pumpApp([billing, orders]);

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }
      final parked = _topLineNumber(tester);

      fill(orders, 50, from: 60);
      await tester.pump();

      expect(_topLineNumber(tester), parked);
    });
  });

  group('clearing resets the position', () {
    test('c on a scrolled pane leaves it live, not blank', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }
      expect(tester.terminalState, containsText('more'));

      await tester.sendKey(LogicalKey.keyC);

      expect(billing.isLive, isTrue);
      expect(tester.terminalState, isNot(containsText('more')));
      expect(tester.terminalState, isNot(containsText('line-')));

      // And it is following again, rather than merely emptied.
      fill(billing, 1, from: 60);
      await tester.pump();

      expect(tester.terminalState, containsText('line-60'));
    });

    test('a child clearing its own screen resets it too', () async {
      // What a reload does, without anyone pressing `c`.
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }
      expect(billing.isLive, isFalse);

      billing.ingest('\x1b[2Jrebuilding\n', isError: false);
      await tester.pump();

      expect(billing.isLive, isTrue);
      expect(tester.terminalState, containsText('rebuilding'));
    });
  });

  group('keys that are not scroll keys still do what they did', () {
    test('shifted J and K do not scroll', () async {
      final billing = session('billing', 8080);
      fill(billing, 60);

      final tester = await pumpApp([billing]);

      await tester.sendKeyEvent(
        const KeyboardEvent(
          logicalKey: LogicalKey.keyK,
          character: 'K',
          modifiers: ModifierKeys(shift: true),
        ),
      );

      expect(billing.isLive, isTrue);
      expect(tester.terminalState, isNot(containsText('more')));
    });

    test('the legend names the scroll keys', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      expect(tester.terminalState, containsText('jk'));
      expect(tester.terminalState, containsText('scroll'));
      expect(tester.terminalState, containsText('live'));
    });
  });
}

/// Everything the terminal is currently showing, as text.
///
/// Built out of the cell buffer because [TerminalState] has no plain-text
/// accessor and its `toString` is the default one.
String _screen(NoctermTester tester) {
  final buffer = tester.terminalState.buffer;
  final rows = <String>[];

  for (var y = 0; y < buffer.height; y++) {
    final row = StringBuffer();
    for (var x = 0; x < buffer.width; x++) {
      row.write(buffer.getCell(x, y).char);
    }
    rows.add(row.toString());
  }

  return rows.join('\n');
}

/// The number of the first `line-N` row the pane is drawing.
///
/// Read off the screen rather than off the session, which keeps these tests
/// honest about what was actually painted: a scroll that moved the model and
/// not the pane would satisfy every assertion made against the model alone.
int _topLineNumber(NoctermTester tester) {
  final screen = _screen(tester);
  final match = RegExp(r'line-(\d+)').firstMatch(screen);
  if (match == null) {
    throw StateError('no line-N row on screen:\n$screen');
  }

  return int.parse(match.group(1)!);
}
