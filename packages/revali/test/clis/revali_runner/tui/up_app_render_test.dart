import 'package:file/memory.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:revali/clis/revali_runner/tui/service_style.dart';
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

  Future<NoctermTester> pumpApp(
    List<ServiceSession> sessions, {
    Size size = const Size(80, 24),
  }) async {
    final tester = await NoctermTester.create(size: size);
    addTearDown(tester.dispose);

    await tester.pumpComponent(
      UpApp(
        sessions: sessions,
        onCommand: (_, _) {},
        onCommandAll: (_) {},
        onQuit: () {},
      ),
    );

    return tester;
  }

  group('the service list', () {
    test('renders every service with its assigned port and state', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);
      final orders = session('orders', 8081);

      final tester = await pumpApp([billing, orders]);

      expect(tester.terminalState, containsText('billing'));
      expect(tester.terminalState, containsText(':8080'));
      expect(tester.terminalState, containsText('serving'));

      expect(tester.terminalState, containsText('orders'));
      expect(tester.terminalState, containsText(':8081'));
      expect(tester.terminalState, containsText('starting'));
    });

    test('marks the focused service, and moves the marker', () async {
      final tester = await pumpApp([
        session('billing', 8080),
        session('orders', 8081),
      ]);

      expect(tester.terminalState, containsText('▸ billing'));
      expect(tester.terminalState, isNot(containsText('▸ orders')));

      await tester.sendKey(LogicalKey.arrowDown);

      expect(tester.terminalState, containsText('▸ orders'));
      expect(tester.terminalState, isNot(containsText('▸ billing')));
    });

    test('keeps a crashed service rather than dropping it', () async {
      final billing = session('billing', 8080);
      final orders = session('orders', 8081)
        ..ingest('Error: no such method\n', isError: true)
        ..markExited(1);

      final tester = await pumpApp([billing, orders]);

      expect(orders.state, ServiceState.crashed);
      expect(tester.terminalState, containsText('orders'));
      expect(tester.terminalState, containsText(':8081'));
      expect(tester.terminalState, containsText('crashed'));
    });

    test("carries the child's own spinner frame while generating", () async {
      final billing = session('billing', 8080)
        ..ingest('⠋ Retrieving constructs', isError: false);

      final tester = await pumpApp([billing]);

      expect(billing.state, ServiceState.generating);
      expect(tester.terminalState, containsText('generating ⠋'));
    });

    test('draws a service in the colour the prefixed stream uses', () async {
      final tester = await pumpApp([
        session('billing', 8080),
        session('orders', 8081),
      ]);

      expect(
        tester.terminalState,
        hasStyledText('billing', TextStyle(color: serviceColor(0))),
      );
      expect(
        tester.terminalState,
        hasStyledText('orders', TextStyle(color: serviceColor(1))),
      );
    });
  });

  group('the log pane', () {
    test('shows the focused service and not another', () async {
      final billing = session('billing', 8080)
        ..ingest('✓ Retrieved constructs (52ms)\n', isError: false);
      final orders = session('orders', 8081)
        ..ingest('✗ orders failed to build\n', isError: true);

      final tester = await pumpApp([billing, orders]);

      expect(tester.terminalState, containsText('✓ Retrieved constructs'));
      expect(tester.terminalState, isNot(containsText('orders failed')));
    });

    test('swaps to the newly focused service', () async {
      final billing = session('billing', 8080)
        ..ingest('✓ Retrieved constructs (52ms)\n', isError: false);
      final orders = session('orders', 8081)
        ..ingest('✗ orders failed to build\n', isError: true);

      final tester = await pumpApp([billing, orders]);

      await tester.sendKey(LogicalKey.arrowDown);

      expect(tester.terminalState, containsText('orders failed to build'));
      expect(tester.terminalState, isNot(containsText('Retrieved constructs')));
    });

    test('drops the name prefix the merged stream needs', () async {
      final billing = session('billing', 8080)
        ..ingest('✓ Retrieved constructs (52ms)\n', isError: false);

      final tester = await pumpApp([billing]);

      expect(tester.terminalState, containsText('✓ Retrieved constructs'));
      expect(tester.terminalState, isNot(containsText('billing |')));
    });

    test('holds one unresolved spinner frame, not a stack of them', () async {
      final billing = session('billing', 8080)
        ..ingest('⠋ Retrieving…', isError: false)
        ..ingest('\r⠙ Retrieving…', isError: false)
        ..ingest('\r⠹ Retrieving…', isError: false);

      final tester = await pumpApp([billing]);

      expect(tester.terminalState, containsText('⠹ Retrieving…'));
      expect(tester.terminalState, isNot(containsText('⠋ Retrieving…')));
      expect(tester.terminalState, isNot(containsText('⠙ Retrieving…')));
    });

    test('shows the newest lines when there are more than fit', () async {
      final billing = session('billing', 8080);
      for (var i = 0; i < 40; i++) {
        billing.ingest('line $i\n', isError: false);
      }

      final tester = await pumpApp([billing], size: const Size(40, 12));

      expect(tester.terminalState, containsText('line 39'));
      expect(tester.terminalState, isNot(containsText('line 5')));
    });
  });

  group('the footer', () {
    test('spells out the focused keys and the shifted fleet keys', () async {
      final tester = await pumpApp([session('billing', 8080)]);

      expect(tester.terminalState, containsText('↑↓ select'));
      expect(tester.terminalState, containsText('r reload'));
      expect(tester.terminalState, containsText('c clear'));
      expect(tester.terminalState, containsText('q quit'));
      expect(tester.terminalState, containsText('R/C/Q all'));
    });
  });
}
