import 'package:file/memory.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:revali/clis/revali_runner/tui/up_app.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

/// `s` bringing a dead service back, and the legend saying so.
///
/// Two halves of one complaint. `r` reaches a running `revali dev` by writing
/// its `.revali_cmd`; once that process is gone there is nobody watching the
/// file, so the key writes into the void and nothing happens — and the legend
/// went on advertising it, which is how a developer concludes the key is
/// broken rather than inapplicable. `s` is the key that actually brings the
/// process back, and the legend now dims whichever of the two would do nothing.
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

  /// A session whose process has exited non-zero, the way one really does.
  ServiceSession crashed(String name, int port) => session(name, port)
    ..ingest('Error: no such method\n', isError: true)
    ..markExited(1);

  /// A session whose `revali dev` is still up with a dead server inside it.
  ///
  /// The state `s` must NOT offer itself for: nothing has exited, so there is
  /// nothing to start — `r` reaches the wrapper that is still watching the file
  /// and that is what brings it back.
  ServiceSession needsFix(String name, int port) =>
      session(name, port)
        ..ingest('[WARN] Failed to bind server: port in use\n', isError: true);

  final restarts = <String>[];
  final commands = <(String name, String command)>[];
  final fleetCommands = <String>[];
  var quits = 0;

  setUp(() {
    restarts.clear();
    commands.clear();
    fleetCommands.clear();
    quits = 0;
  });

  /// Draws [sessions] on an existing tester.
  ///
  /// Separate from [pumpApp] because nocterm allows one binding per test, so a
  /// test that wants to compare two fleets has to redraw rather than stand a
  /// second screen up beside the first.
  Future<void> render(
    NoctermTester tester,
    List<ServiceSession> sessions, {
    bool withRestart = true,
  }) => tester.pumpComponent(
    UpApp(
      sessions: sessions,
      onCommand: (session, command) => commands.add((session.name, command)),
      onCommandAll: fleetCommands.add,
      onQuit: () => quits++,
      onRestart: withRestart ? (session) => restarts.add(session.name) : null,
    ),
  );

  Future<NoctermTester> pumpApp(
    List<ServiceSession> sessions, {
    bool withRestart = true,
    Size size = const Size(80, 24),
  }) async {
    final tester = await NoctermTester.create(size: size);
    addTearDown(tester.dispose);

    await render(tester, sessions, withRestart: withRestart);

    return tester;
  }

  group('the s key', () {
    test('brings back the focused service when it is crashed', () async {
      final tester = await pumpApp([crashed('billing', 8080)]);

      await tester.sendKey(LogicalKey.keyS);

      expect(restarts, ['billing']);
    });

    test('brings back a service that exited cleanly', () async {
      final stopped = session('billing', 8080)..markExited(0);
      final tester = await pumpApp([stopped]);

      expect(stopped.state, ServiceState.stopped);

      await tester.sendKey(LogicalKey.keyS);

      expect(restarts, ['billing']);
    });

    test('acts on the focused service, not the one that is dead', () async {
      final tester = await pumpApp([
        session('billing', 8080),
        crashed('orders', 8081),
      ]);

      // `billing` is focused and alive: nothing to start.
      await tester.sendKey(LogicalKey.keyS);
      expect(restarts, isEmpty);

      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.keyS);

      expect(restarts, ['orders']);
    });

    test('does nothing at a service that is still running', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      await tester.sendKey(LogicalKey.keyS);

      expect(
        restarts,
        isEmpty,
        reason: 'starting a live service would spawn a second process',
      );
    });

    test('does nothing at a service that only needs a fix', () async {
      final billing = needsFix('billing', 8080);
      final tester = await pumpApp([billing]);

      expect(billing.state, ServiceState.failed);

      await tester.sendKey(LogicalKey.keyS);

      expect(
        restarts,
        isEmpty,
        reason: '`revali dev` is still up here; `r` is what reaches it',
      );
    });

    test('does nothing once the fleet is draining', () async {
      final tester = await pumpApp([crashed('billing', 8080)]);

      await tester.sendKeyEvent(
        const KeyboardEvent(
          logicalKey: LogicalKey.keyC,
          modifiers: ModifierKeys(ctrl: true),
        ),
      );
      expect(quits, 1);

      await tester.sendKey(LogicalKey.keyS);

      expect(
        restarts,
        isEmpty,
        reason:
            'every other child has had its SIGTERM; starting one more '
            'would be spawning into a shutdown',
      );
    });

    test('S is not a fleet-wide start', () async {
      final tester = await pumpApp([crashed('billing', 8080)]);

      await tester.sendKeyEvent(
        const KeyboardEvent(
          logicalKey: LogicalKey.keyS,
          character: 'S',
          modifiers: ModifierKeys(shift: true),
        ),
      );

      expect(restarts, isEmpty);
      expect(
        fleetCommands,
        isEmpty,
        reason:
            'S must not fall through to the shifted command branch and '
            'broadcast an "s" no child understands',
      );
      expect(commands, isEmpty);
    });

    test('is inert, and unadvertised, when no restart seam is wired', () async {
      final tester = await pumpApp([
        crashed('billing', 8080),
      ], withRestart: false);

      await tester.sendKey(LogicalKey.keyS);

      expect(restarts, isEmpty);
      expect(_legend(tester), isNot(contains('s start')));
    });
  });

  group('the legend', () {
    test('offers reload and dims start while a service is serving', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);
      final tester = await pumpApp([billing]);

      expect(billing.state, ServiceState.serving);

      expect(_isLive(tester, 'r reload'), isTrue);
      expect(_isLive(tester, 'q quit'), isTrue);
      expect(
        _isLive(tester, 's start'),
        isFalse,
        reason: 'there is nothing to start; the process is right there',
      );
    });

    test('offers start and dims reload once the process is gone', () async {
      final tester = await pumpApp([crashed('billing', 8080)]);

      expect(_isLive(tester, 's start'), isTrue);
      expect(
        _isLive(tester, 'r reload'),
        isFalse,
        reason: 'reload writes .revali_cmd, which nothing is left to read',
      );
      expect(
        _isLive(tester, 'q quit'),
        isFalse,
        reason: 'quit travels the same dead channel reload does',
      );
    });

    test('keeps reload live at a service that only needs a fix', () async {
      final tester = await pumpApp([needsFix('billing', 8080)]);

      expect(
        _isLive(tester, 'r reload'),
        isTrue,
        reason: '`needs fix` is the state a reload actually recovers',
      );
      expect(_isLive(tester, 's start'), isFalse);
    });

    test('never dims the fleet keys or the way out', () async {
      final serving = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);

      final tester = await pumpApp([serving]);

      for (final sessions in [
        [serving],
        [crashed('orders', 8081)],
        [needsFix('users', 8082)],
      ]) {
        await render(tester, sessions);

        const always = [
          '↑↓ select',
          'jk scroll',
          'g live',
          'c clear',
          'R/C/Q all',
          '^C exit',
        ];

        for (final hint in always) {
          expect(
            _isLive(tester, hint),
            isTrue,
            reason:
                '"$hint" applies whatever the focused service is doing, '
                'and ${sessions.single.state.name} is what it is doing',
          );
        }
      }
    });

    test('does not reorder or resize between states', () async {
      final serving = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);

      final tester = await pumpApp([serving]);
      final alive = _legend(tester);

      await render(tester, [crashed('billing', 8080)]);
      final dead = _legend(tester);

      expect(
        dead,
        alive,
        reason:
            'the legend may change colour between states and nothing '
            'else — an item that moves is harder to use than a static one',
      );

      // And the whole line is on screen, which the version before the start
      // key was not: it ran off the right border and clipped `^C exit` to
      // `^C e`, which is the one hint that must never be unreadable.
      expect(alive, contains('^C exit'));
      expect(alive.length, lessThanOrEqualTo(78));
    });

    test('follows the focused service without a keypress', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);
      final tester = await pumpApp([billing]);

      expect(_isLive(tester, 'r reload'), isTrue);

      // The child dies. Nobody presses anything — which is exactly the case a
      // legend read once at build time would get wrong, and it would keep
      // getting it wrong until the next unrelated keystroke.
      billing.markExited(1);
      await tester.pump();

      expect(_isLive(tester, 'r reload'), isFalse);
      expect(_isLive(tester, 's start'), isTrue);
    });

    test('follows the selection between a live and a dead service', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);
      final tester = await pumpApp([billing, crashed('orders', 8081)]);

      expect(_isLive(tester, 'r reload'), isTrue);

      await tester.sendKey(LogicalKey.arrowDown);

      expect(_isLive(tester, 's start'), isTrue);
      expect(_isLive(tester, 'r reload'), isFalse);
    });
  });
}

/// Where the legend is on screen: its row, and the column it starts at.
///
/// Found by content rather than by position. The pane above the legend is sized
/// by whatever is left over, so the row moves with the terminal, and the frame
/// means the line does not start at column zero.
({int row, int column}) _legendAt(NoctermTester tester) {
  final buffer = tester.terminalState.buffer;

  // From the bottom: the legend is the last thing inside the frame, and `↑↓`
  // appears nowhere else on the screen.
  for (var y = buffer.height - 1; y >= 0; y--) {
    for (var x = 0; x < buffer.width; x++) {
      if (buffer.getCell(x, y).char == '↑') return (row: y, column: x);
    }
  }

  throw StateError('no legend row on screen');
}

/// The legend, as text, with the frame trimmed off the front — so a column
/// index into this string is an offset into the legend itself.
String _legend(NoctermTester tester) {
  final (:row, :column) = _legendAt(tester);
  final buffer = tester.terminalState.buffer;
  final text = StringBuffer();

  for (var x = column; x < buffer.width; x++) {
    text.write(buffer.getCell(x, row).char);
  }

  // The frame's right border, and the padding before it, are not the legend.
  return text.toString().replaceAll('│', ' ').trimRight();
}

/// Whether the hint beginning with [hint] is drawn as available.
///
/// Read off the cell the hint's *key* occupies, which is the character a
/// reader's eye lands on: a disabled hint is drawn in [Colors.brightBlack] and
/// an enabled one in white. Asserted against the rendered buffer rather than
/// against the component's inputs, because a legend that computed the right
/// answer and painted the wrong one would satisfy every assertion made against
/// the inputs alone.
bool _isLive(NoctermTester tester, String hint) {
  final legend = _legend(tester);
  final offset = legend.indexOf(hint);
  if (offset == -1) {
    throw StateError('no "$hint" in the legend: $legend');
  }

  final (:row, :column) = _legendAt(tester);
  final cell = tester.terminalState.buffer.getCell(column + offset, row);

  return cell.style.color != Colors.brightBlack;
}
