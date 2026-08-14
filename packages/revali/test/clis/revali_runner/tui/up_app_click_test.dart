import 'package:file/memory.dart';
import 'package:nocterm/nocterm.dart' hide isEmpty, isNotEmpty;
import 'package:revali/clis/revali_runner/tui/up_app.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

/// Clicking the screen: roster rows, full URLs, and route paths.
///
/// Nothing here opens a browser. The opener is a seam — [UpApp.onOpenUrl] —
/// and every test asserts the URL that WOULD have been launched, which is the
/// whole of what this side controls.
///
/// The group that earns the design is "a click resolves against what is on
/// screen": a click must land on the row that is actually painted, not on an
/// index into the buffer. Scrolled up — or with a `── redraw ──` rule part way
/// through — those two are different numbers, and getting it wrong opens the
/// wrong URL, which is worse than opening none.
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

  /// The pane, with somewhere for opened URLs to land.
  Future<(NoctermTester, List<String>)> pumpApp(
    List<ServiceSession> sessions, {
    Size size = const Size(80, 24),
    bool withOpener = true,
  }) async {
    final opened = <String>[];

    final tester = await NoctermTester.create(size: size);
    addTearDown(tester.dispose);

    await tester.pumpComponent(
      UpApp(
        sessions: sessions,
        onCommand: (_, _) {},
        onCommandAll: (_) {},
        onQuit: () {},
        onOpenUrl: withOpener ? opened.add : null,
      ),
    );

    return (tester, opened);
  }

  group('a service row in the roster', () {
    test('clicking one focuses that service', () async {
      final billing = session('billing', 8080)
        ..ingest('billing-output\n', isError: false);
      final orders = session('orders', 8081)
        ..ingest('orders-output\n', isError: false);

      final (tester, _) = await pumpApp([billing, orders]);

      // `billing` is focused to start with, so its pane is the one drawn.
      expect(tester.terminalState, containsText('billing-output'));
      expect(tester.terminalState, isNot(containsText('orders-output')));

      await tester.tap(_columnOf(tester, 'orders'), _rowOf(tester, 'orders'));

      expect(
        tester.terminalState,
        containsText('orders-output'),
        reason: 'clicking a roster row must show that service',
      );
      expect(tester.terminalState, isNot(containsText('billing-output')));
    });

    test('it lands where the arrow keys land', () async {
      // One definition of "select a service", reached two ways. Driven through
      // a single tester because nocterm allows one binding at a time.
      final billing = session('billing', 8080);
      final orders = session('orders', 8081)
        ..ingest('orders-output\n', isError: false);

      final (tester, _) = await pumpApp([billing, orders]);

      await tester.tap(_columnOf(tester, 'orders'), _rowOf(tester, 'orders'));
      final clicked = _screen(tester);

      // Back to the top and down again, this time on the keys.
      await tester.sendKey(LogicalKey.arrowUp);
      expect(_screen(tester), isNot(clicked));
      await tester.sendKey(LogicalKey.arrowDown);

      expect(_screen(tester), clicked);
    });

    test('a scrolled roster selects the row that is on screen', () async {
      // Only three rows are ever visible and the window follows the focus, so
      // roster row 1 is not service 1 once the selection has moved down.
      final sessions = [
        for (var i = 0; i < 9; i++)
          session('svc$i', 8080 + i)..ingest('output-$i\n', isError: false),
      ];

      final (tester, _) = await pumpApp(sessions);

      // Walk down to svc5; the window now shows svc4, svc5, svc6.
      for (var i = 0; i < 5; i++) {
        await tester.sendKey(LogicalKey.arrowDown);
      }
      expect(tester.terminalState, containsText('output-5'));

      // The FIRST visible roster row is svc4, not svc0.
      await tester.tap(_columnOf(tester, 'svc4'), _rowOf(tester, 'svc4'));

      expect(
        tester.terminalState,
        containsText('output-4'),
        reason: 'the top roster row is the top VISIBLE row, not service 0',
      );
      expect(tester.terminalState, isNot(containsText('output-0')));
    });
  });

  group('a full URL in the log pane', () {
    test('clicking one resolves to that URL', () async {
      final billing = session('billing', 8080)
        ..ingest(
          'The Dart VM service is listening on http://127.0.0.1:52345/abc=/\n',
          isError: false,
        );

      final (tester, opened) = await pumpApp([billing]);

      await tester.tap(
        _columnOf(tester, 'http://127.0.0.1:52345'),
        _rowOf(tester, 'http://127.0.0.1:52345'),
      );

      expect(opened, ['http://127.0.0.1:52345/abc=/']);
    });

    test('a wildcard address opens as localhost', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);

      await tester.tap(
        _columnOf(tester, 'http://0.0.0.0'),
        _rowOf(tester, 'http://0.0.0.0'),
      );

      expect(opened, ['http://localhost:8080/api']);
    });

    test('the displayed text is untouched', () async {
      // The line says what the service actually bound. Rewriting it on screen
      // would be this side lying about the other side's output.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final (tester, _) = await pumpApp([billing]);

      expect(
        tester.terminalState,
        containsText('Serving at http://0.0.0.0:8080/api'),
      );
      expect(tester.terminalState, isNot(containsText('localhost')));
    });

    test('clicking the prose beside it opens nothing', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);

      await tester.tap(
        _columnOf(tester, 'Serving at'),
        _rowOf(tester, 'Serving at'),
      );

      expect(opened, isEmpty);
    });
  });

  group('a route path', () {
    /// A service that has announced its address and printed its route table.
    ServiceSession serving() => session('billing', 8080)
      ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false)
      ..ingest('GET       -> /billing/invoices\n', isError: false)
      ..ingest('POST      -> /billing/payments\n', isError: false);

    test('clicking it opens the base URL plus the path', () async {
      final (tester, opened) = await pumpApp([serving()]);

      await tester.tap(
        _columnOf(tester, '/billing/invoices'),
        _rowOf(tester, '/billing/invoices'),
      );

      expect(opened, ['http://localhost:8080/api/billing/invoices']);
    });

    test('the row renders exactly as it did before', () async {
      // The contract: only the behaviour changes. Same text, same columns.
      final (tester, _) = await pumpApp([serving()]);

      expect(tester.terminalState, containsText('GET       -> '
          '/billing/invoices'));
    });

    test('a POST row opens nothing', () async {
      final (tester, opened) = await pumpApp([serving()]);

      await tester.tap(
        _columnOf(tester, '/billing/payments'),
        _rowOf(tester, '/billing/payments'),
      );

      expect(opened, isEmpty);
    });

    test('clicking the method opens nothing', () async {
      final (tester, opened) = await pumpApp([serving()]);

      await tester.tap(
        _columnOf(tester, 'GET'),
        _rowOf(tester, 'GET       -> /billing/invoices'),
      );

      expect(opened, isEmpty);
    });

    test('before the service is serving, it resolves to nothing', () async {
      // The route table can be printed before — or without — an address. There
      // is no base to join to, and guessing one sends the click somewhere
      // wrong.
      final billing = session('billing', 8080)
        ..ingest('GET       -> /billing/invoices\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);

      await tester.tap(
        _columnOf(tester, '/billing/invoices'),
        _rowOf(tester, '/billing/invoices'),
      );

      expect(opened, isEmpty);
    });

    test('it becomes clickable once the address arrives', () async {
      final billing = session('billing', 8080)
        ..ingest('GET       -> /billing/invoices\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);

      billing.ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);
      await tester.pump();

      await tester.tap(
        _columnOf(tester, '/billing/invoices'),
        _rowOf(tester, '/billing/invoices'),
      );

      expect(opened, ['http://localhost:8080/api/billing/invoices']);
    });

    test('each service resolves against its own address', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false)
        ..ingest('GET       -> /invoices\n', isError: false);
      final orders = session('orders', 8081)
        ..ingest('Serving at http://0.0.0.0:8081/v2\n', isError: false)
        ..ingest('GET       -> /invoices\n', isError: false);

      final (tester, opened) = await pumpApp([billing, orders]);

      await tester.tap(
        _columnOf(tester, '/invoices'),
        _rowOf(tester, '/invoices'),
      );

      await tester.sendKey(LogicalKey.arrowDown);
      await tester.tap(
        _columnOf(tester, '/invoices'),
        _rowOf(tester, '/invoices'),
      );

      expect(opened, [
        'http://localhost:8080/api/invoices',
        'http://localhost:8081/v2/invoices',
      ]);
    });
  });

  group('a click resolves against what is on screen', () {
    test('scrolled up, it opens the visible line and not the buffer index',
        () async {
      // The regression this whole design exists to make impossible. Every line
      // carries a DIFFERENT URL, so resolving against the wrong row opens a
      // provably wrong address rather than coincidentally the right one.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      for (var i = 0; i < 60; i++) {
        billing.ingest('GET       -> /route-$i\n', isError: false);
      }

      final (tester, opened) = await pumpApp([billing]);

      // At the live end the newest lines are on screen.
      expect(tester.terminalState, containsText('/route-59'));

      for (var i = 0; i < 12; i++) {
        await tester.sendKey(LogicalKey.keyK);
      }

      // Some earlier route is now the one on screen. Whichever it is, the
      // click must open THAT one.
      const target = '/route-40';
      expect(tester.terminalState, containsText(target));

      await tester.tap(_columnOf(tester, target), _rowOf(tester, target));

      expect(opened, ['http://localhost:8080/api$target']);
    });

    test('a redraw rule in the buffer does not shift the target', () async {
      // up-board: a child's own `ESC[2J` becomes a `── redraw ──` LINE and the
      // history stays. That line occupies a row, so any arithmetic from a
      // buffer index would now be off by one per rule.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false)
        ..ingest('GET       -> /before\n', isError: false)
        ..ingest('\x1B[2J', isError: false)
        ..ingest('GET       -> /after\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);

      expect(tester.terminalState, containsText('redraw'));

      await tester.tap(_columnOf(tester, '/before'), _rowOf(tester, '/before'));
      await tester.tap(_columnOf(tester, '/after'), _rowOf(tester, '/after'));

      expect(opened, [
        'http://localhost:8080/api/before',
        'http://localhost:8080/api/after',
      ]);
    });

    test('after a clear, an old line is not still clickable', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false)
        ..ingest('GET       -> /billing/invoices\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);
      final column = _columnOf(tester, '/billing/invoices');
      final row = _rowOf(tester, '/billing/invoices');

      billing.clear();
      await tester.pump();

      await tester.tap(column, row);

      expect(opened, isEmpty);
    });
  });

  group('the wheel and the click share one stream', () {
    test('a wheel notch opens nothing', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final (tester, opened) = await pumpApp([billing]);

      final row = _rowOf(tester, 'http://0.0.0.0');
      final column = _columnOf(tester, 'http://0.0.0.0');

      await tester.sendMouseEvent(
        MouseEvent(
          button: MouseButton.wheelUp,
          pressed: true,
          x: column,
          y: row,
        ),
      );
      await tester.sendMouseEvent(
        MouseEvent(
          button: MouseButton.wheelDown,
          pressed: true,
          x: column,
          y: row,
        ),
      );

      expect(opened, isEmpty);
    });

    test('a click does not scroll the pane', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      for (var i = 0; i < 60; i++) {
        billing.ingest('line-$i\n', isError: false);
      }

      final (tester, _) = await pumpApp([billing]);
      final before = _screen(tester);

      await tester.tap(_columnOf(tester, 'line-59'), _rowOf(tester, 'line-59'));

      expect(billing.isLive, isTrue);
      expect(_screen(tester), before);
      expect(tester.terminalState, isNot(containsText('more')));
    });

    test('scrolling still works after a click', () async {
      final billing = session('billing', 8080);
      for (var i = 0; i < 60; i++) {
        billing.ingest('line-$i\n', isError: false);
      }

      final (tester, _) = await pumpApp([billing]);

      await tester.tap(_columnOf(tester, 'line-59'), _rowOf(tester, 'line-59'));
      await tester.sendMouseEvent(
        const MouseEvent(
          button: MouseButton.wheelUp,
          pressed: true,
          x: 10,
          y: 10,
        ),
      );

      expect(tester.terminalState, containsText('more'));
    });
  });

  group('discoverability', () {
    test('a clickable run is underlined and a dead one is not', () async {
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final (tester, _) = await pumpApp([billing]);

      final row = _rowOf(tester, 'http://0.0.0.0');
      final buffer = tester.terminalState.buffer;

      expect(
        buffer.getCell(_columnOf(tester, 'http://0.0.0.0'), row)
            .style
            .decoration,
        isNotNull,
        reason: 'the URL says it can be clicked',
      );
      expect(
        buffer.getCell(_columnOf(tester, 'Serving at'), row).style.decoration,
        isNull,
        reason: 'the prose beside it does not',
      );
    });

    test('nothing is underlined when there is no opener', () async {
      // A screen that advertises a click nothing is listening for is worse
      // than one that advertises nothing.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false);

      final (tester, _) = await pumpApp([billing], withOpener: false);

      expect(
        tester.terminalState.buffer
            .getCell(
              _columnOf(tester, 'http://0.0.0.0'),
              _rowOf(tester, 'http://0.0.0.0'),
            )
            .style
            .decoration,
        isNull,
      );
    });

    test('a link that straddles a colour change is still one link', () async {
      // A link range is found over the joined plain text, so it pays no
      // attention to where one SGR run stops and the next starts. Both halves
      // have to stay clickable, and each has to keep the colour it was given.
      final billing = session('billing', 8080)
        ..ingest(
          'Serving at \x1B[92mhttp://0.0.0.0\x1B[0m:8080/api\n',
          isError: false,
        );

      final (tester, opened) = await pumpApp([billing]);

      expect(
        tester.terminalState,
        containsText('Serving at http://0.0.0.0:8080/api'),
      );

      // The coloured half.
      await tester.tap(
        _columnOf(tester, 'http://0.0.0.0'),
        _rowOf(tester, 'http://0.0.0.0'),
      );
      // The half after the reset.
      await tester.tap(
        _columnOf(tester, ':8080/api'),
        _rowOf(tester, ':8080/api'),
      );

      expect(opened, [
        'http://localhost:8080/api',
        'http://localhost:8080/api',
      ]);
    });

    test('a route path keeps its own colour', () async {
      // The table is colour coded by method and the path is grey. Repainting
      // it to say "clickable" would take away what the colour already said.
      final billing = session('billing', 8080)
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false)
        ..ingest(
          '\x1B[93mGET       \x1B[0m\x1B[90m-> \x1B[0m/billing/invoices\n',
          isError: false,
        );

      final (tester, opened) = await pumpApp([billing]);

      expect(tester.terminalState, containsText('GET       -> '
          '/billing/invoices'));

      await tester.tap(
        _columnOf(tester, '/billing/invoices'),
        _rowOf(tester, '/billing/invoices'),
      );

      expect(opened, ['http://localhost:8080/api/billing/invoices']);
    });
  });
}

/// Everything the terminal is showing, as text.
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

/// The screen row [text] is drawn on.
///
/// Found by reading the cell buffer rather than computed, which is the point:
/// a test that worked out where a line *should* be would share the arithmetic
/// with the bug it is meant to catch.
int _rowOf(NoctermTester tester, String text) {
  final rows = _screen(tester).split('\n');

  for (final (index, row) in rows.indexed) {
    if (row.contains(text)) return index;
  }

  throw StateError('"$text" is not on screen:\n${rows.join('\n')}');
}

/// A column inside [text] where it is drawn — one in from its start, so the
/// tap lands squarely on the run rather than on its first cell.
int _columnOf(NoctermTester tester, String text) {
  final rows = _screen(tester).split('\n');

  for (final row in rows) {
    final start = row.indexOf(text);
    if (start != -1) return start + 1;
  }

  throw StateError('"$text" is not on screen:\n${rows.join('\n')}');
}
