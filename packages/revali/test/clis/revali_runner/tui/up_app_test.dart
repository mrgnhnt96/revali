import 'package:file/memory.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:revali/clis/revali_runner/tui/up_app.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fs;

  setUp(() => fs = MemoryFileSystem());

  /// A session for a service that would have been planned at [port].
  ///
  /// Ports are assigned in discovery order, which is alphabetical, so `billing`
  /// takes the base port and `orders` the next — the tests below spell that out
  /// rather than relying on it, since the list is where anyone reads it.
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

  /// Records every callback the app makes, so a test can assert on what did
  /// *not* fire as easily as on what did.
  final commands = <(String name, String command)>[];
  final fleetCommands = <String>[];
  var quits = 0;

  setUp(() {
    commands.clear();
    fleetCommands.clear();
    quits = 0;
  });

  Future<void> pumpApp(
    NoctermTester tester,
    List<ServiceSession> sessions,
  ) async {
    await tester.pumpComponent(
      UpApp(
        sessions: sessions,
        onCommand: (session, command) => commands.add((session.name, command)),
        onCommandAll: fleetCommands.add,
        onQuit: () => quits++,
      ),
    );
  }

  /// A shifted letter as a terminal actually delivers it: the same logical key
  /// as the unshifted one, carrying the uppercase character.
  KeyboardEvent shifted(LogicalKey key, String character) => KeyboardEvent(
    logicalKey: key,
    character: character,
    modifiers: const ModifierKeys(shift: true),
  );

  group('keys act on the focused service', () {
    test('r reloads only the service the arrow keys moved to', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      final billing = session('billing', 8080);
      final orders = session('orders', 8081);

      await pumpApp(tester, [billing, orders]);

      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.keyR);

      expect(commands, [('orders', UpCommand.reload)]);
      expect(
        commands.map((c) => c.$1),
        isNot(contains('billing')),
        reason: 'the unfocused service must not be reloaded',
      );
      expect(fleetCommands, isEmpty);
    });

    test('r reloads the first service when nothing was selected', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKey(LogicalKey.keyR);

      expect(commands, [('billing', UpCommand.reload)]);
    });

    test('c and q carry their own commands', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [session('billing', 8080)]);

      await tester.sendKey(LogicalKey.keyC);
      await tester.sendKey(LogicalKey.keyQ);

      expect(commands, [
        ('billing', UpCommand.clear),
        ('billing', UpCommand.quit),
      ]);
    });
  });

  group('shifted keys act on the fleet', () {
    test('R, C and Q reach the all-callback and not the focused one', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKeyEvent(shifted(LogicalKey.keyR, 'R'));
      await tester.sendKeyEvent(shifted(LogicalKey.keyC, 'C'));
      await tester.sendKeyEvent(shifted(LogicalKey.keyQ, 'Q'));

      expect(fleetCommands, [
        UpCommand.reload,
        UpCommand.clear,
        UpCommand.quit,
      ]);
      expect(commands, isEmpty);
    });

    test('a shift modifier with no character still reads as shifted', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [session('billing', 8080)]);

      await tester.sendKeyEvent(
        const KeyboardEvent(
          logicalKey: LogicalKey.keyR,
          modifiers: ModifierKeys(shift: true),
        ),
      );

      expect(fleetCommands, [UpCommand.reload]);
      expect(commands, isEmpty);
    });
  });

  group('quitting', () {
    test('ctrl+C tears the screen down without touching a service', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [session('billing', 8080)]);

      await tester.sendKeyEvent(
        const KeyboardEvent(
          logicalKey: LogicalKey.keyC,
          modifiers: ModifierKeys(ctrl: true),
        ),
      );

      expect(quits, 1);
      expect(commands, isEmpty);
      expect(fleetCommands, isEmpty);
    });

    test('ctrl+r does not fall through to a plain reload', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [session('billing', 8080)]);

      await tester.sendKeyEvent(
        const KeyboardEvent(
          logicalKey: LogicalKey.keyR,
          modifiers: ModifierKeys(ctrl: true),
        ),
      );

      expect(commands, isEmpty);
      expect(fleetCommands, isEmpty);
    });
  });

  group('selection', () {
    test('wraps off the top to the last service', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [
        session('billing', 8080),
        session('orders', 8081),
        session('shipping', 8082),
      ]);

      await tester.sendKey(LogicalKey.arrowUp);
      await tester.sendKey(LogicalKey.keyR);

      expect(commands, [('shipping', UpCommand.reload)]);
    });

    test('wraps off the bottom back to the first service', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.keyR);

      expect(commands, [('billing', UpCommand.reload)]);
    });

    test('digits select by position', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [
        session('billing', 8080),
        session('orders', 8081),
        session('shipping', 8082),
      ]);

      await tester.sendKey(LogicalKey.digit3);
      await tester.sendKey(LogicalKey.keyR);

      expect(commands, [('shipping', UpCommand.reload)]);
    });

    test('a digit past the end of the fleet is ignored', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, [
        session('billing', 8080),
        session('orders', 8081),
      ]);

      await tester.sendKey(LogicalKey.digit9);
      await tester.sendKey(LogicalKey.keyR);

      expect(commands, [('billing', UpCommand.reload)]);
    });
  });

  group('an empty fleet', () {
    test('renders and swallows keys rather than throwing', () async {
      final tester = await NoctermTester.create();
      addTearDown(tester.dispose);

      await pumpApp(tester, []);

      await tester.sendKey(LogicalKey.arrowDown);
      await tester.sendKey(LogicalKey.keyR);

      expect(tester.terminalState, containsText('No services.'));
      expect(commands, isEmpty);
    });
  });
}
