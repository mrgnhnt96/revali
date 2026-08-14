import 'package:file/memory.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fs;

  setUp(() => fs = MemoryFileSystem());

  ServiceSession session({int maxLines = ServiceSession.defaultMaxLines}) {
    fs.directory('/repo/svc/orders').createSync(recursive: true);

    return ServiceSession(
      ServicePlan(
        service: RevaliService(
          name: 'orders',
          directory: fs.directory('/repo/svc/orders'),
          relativePath: 'svc/orders',
        ),
        port: 8080,
        label: 'orders',
      ),
      maxLines: maxLines,
    );
  }

  /// Feeds stdout the way a pipe does: one write at a time.
  ///
  /// Handing over one joined string instead would collapse the animation
  /// inside a single chunk and never exercise the case that matters.
  void write(ServiceSession it, List<String> chunks, {bool isError = false}) {
    for (final chunk in chunks) {
      it.ingest(chunk, isError: isError);
    }
  }

  List<String> texts(ServiceSession it) => [
    for (final line in it.lines) line.text,
  ];

  group('reads the plan', () {
    test('exposes the name, label and assigned port', () {
      final it = session();

      expect(it.name, 'orders');
      expect(it.label, 'orders');
      expect(it.port, 8080);
    });
  });

  group('ingest', () {
    test('settles a plain line once it is terminated', () {
      final it = session();

      write(it, ['hello\n']);

      expect(texts(it), ['hello']);
    });

    test('holds a line that has no newline yet, without duplicating it', () {
      // The pipe can split anywhere. Showing the half line is right — it is
      // on screen in a real terminal — but it must not settle twice.
      final it = session();

      write(it, ['Serving at http://']);
      expect(texts(it), ['Serving at http://']);

      write(it, ['0.0.0.0:8080\n']);
      expect(texts(it), ['Serving at http://0.0.0.0:8080']);
    });

    test('drops blank lines', () {
      final it = session();

      write(it, ['one\n', '\n', '  \n', 'two\n']);

      expect(texts(it), ['one', 'two']);
    });

    test('ignores an empty chunk', () {
      final it = session();

      write(it, ['']);

      expect(it.lines, isEmpty);
    });

    test('records which stream a line came from', () {
      final it = session();

      write(it, ['out\n']);
      write(it, ['err\n'], isError: true);

      expect(it.lines, const [
        ServiceLogLine('out', isError: false),
        ServiceLogLine('err', isError: true),
      ]);
    });

    test('notifies its listeners', () {
      final it = session();
      var notifications = 0;
      it.addListener(() => notifications++);

      write(it, ['one\n', 'two\n']);

      expect(notifications, 2);
    });

    test('keeps a stdout tail apart from an interleaved stderr chunk', () {
      // One buffer for both streams would splice the half written stdout line
      // onto the stderr chunk and corrupt both.
      final it = session();

      write(it, ['half ']);
      write(it, ['a warning\n'], isError: true);
      write(it, ['a line\n']);

      expect(texts(it), ['a warning', 'half a line']);
    });
  });

  group('a spinner', () {
    // What `revali up` actually receives while a child generates code: a
    // frame per write, each redrawing the last with a bare carriage return,
    // and no newline until the step resolves.
    const frames = [
      '⠋ Retrieving constructs...',
      '\r⠙ Retrieving constructs...',
      '\r⠹ Retrieving constructs...',
      '\r⠸ Retrieving constructs...',
    ];

    test('animates in place as one line rather than stacking', () {
      final it = session();

      for (final (index, frame) in frames.indexed) {
        it.ingest(frame, isError: false);

        expect(
          it.lines,
          hasLength(1),
          reason: 'frame ${index + 1} stacked instead of replacing',
        );
      }

      expect(texts(it), ['⠸ Retrieving constructs...']);
    });

    test('settles when it resolves, leaving only the result', () {
      final it = session();

      write(it, [...frames, '\r✓ Retrieved constructs (61ms)\n']);

      expect(texts(it), ['✓ Retrieved constructs (61ms)']);
    });

    test('settles a failure the same way', () {
      final it = session();

      write(it, [...frames, '\r✗ Failed to retrieve constructs\n']);

      expect(texts(it), ['✗ Failed to retrieve constructs']);
    });

    test('stays replaceable even when a frame ends in a newline', () {
      final it = session();

      write(it, [
        '⠋ Generating server code...\n',
        '⠙ Generating server code...\n',
      ]);

      expect(texts(it), ['⠙ Generating server code...']);
    });

    test('does not grow its buffer for every frame it ever drew', () {
      // A step can run for minutes at a frame every 80ms. Only the text after
      // the last carriage return can still matter.
      final it = session();

      for (var i = 0; i < 500; i++) {
        it.ingest('\r⠋ Retrieving constructs...', isError: false);
      }
      it.ingest('\r✓ Retrieved constructs\n', isError: false);

      expect(texts(it), ['✓ Retrieved constructs']);
    });

    test('a settled line after it is kept, not replaced', () {
      final it = session();

      write(it, [
        '⠋ Retrieving constructs...',
        '\r✓ Retrieved constructs\n',
        '⠋ Generating server code...',
        '\r✓ Generated server code\n',
      ]);

      expect(texts(it), ['✓ Retrieved constructs', '✓ Generated server code']);
    });
  });

  group('line endings', () {
    test('a CRLF line survives intact', () {
      // A trailing carriage return is the other half of a CRLF ending, not a
      // redraw. Treating it as one discards the whole line on Windows.
      final it = session();

      write(it, ['one\r\n', 'two\r\n']);

      expect(texts(it), ['one', 'two']);
    });

    test('a CRLF split across chunks survives intact', () {
      final it = session();

      write(it, ['one\r', '\ntwo\r', '\n']);

      expect(texts(it), ['one', 'two']);
    });

    test('a redraw followed by a CRLF ending keeps the final frame', () {
      final it = session();

      write(it, ['⠋ Retrieving...\r✓ Retrieved\r\n']);

      expect(texts(it), ['✓ Retrieved']);
    });
  });

  group('the ring buffer', () {
    test('evicts oldest first at its cap', () {
      final it = session(maxLines: 3);

      write(it, [for (var i = 1; i <= 5; i++) 'line $i\n']);

      expect(texts(it), ['line 3', 'line 4', 'line 5']);
    });

    test('holds everything below its cap', () {
      final it = session(maxLines: 3);

      write(it, ['line 1\n', 'line 2\n']);

      expect(texts(it), ['line 1', 'line 2']);
    });

    test('does not count a transient frame against the cap', () {
      // The frame being drawn is not settled yet; charging it a slot would
      // evict a real line to hold something about to be overwritten.
      final it = session(maxLines: 3);

      write(it, ['line 1\n', 'line 2\n', 'line 3\n', '⠋ Retrieving...']);

      expect(texts(it), ['line 1', 'line 2', 'line 3', '⠋ Retrieving...']);
    });

    test('defaults to a cap deep enough for a trace and its build', () {
      expect(ServiceSession.defaultMaxLines, 500);
    });
  });

  group('state', () {
    test('starts as starting', () {
      expect(session().state, ServiceState.starting);
    });

    test('is generating while a step is in flight', () {
      final it = session();

      write(it, ['⠋ Retrieving constructs...']);

      expect(it.state, ServiceState.generating);
    });

    test('stays generating once a step resolves', () {
      // The next step is coming; nothing has said it is listening yet.
      final it = session();

      write(it, ['⠋ Retrieving constructs...', '\r✓ Retrieved constructs\n']);

      expect(it.state, ServiceState.generating);
    });

    test('is serving once it announces an address', () {
      final it = session();

      write(it, ['Serving at http://0.0.0.0:8080/api\n']);

      expect(it.state, ServiceState.serving);
    });

    test('is serving even when the child colours the line', () {
      // The child hands it to `logger.success`, so it arrives wrapped in an
      // ANSI escape and no longer begins with the `S`.
      final it = session();

      write(it, ['\x1B[92mServing at http://0.0.0.0:8080\x1B[0m\n']);

      expect(it.state, ServiceState.serving);
    });

    test('is serving before the announcing line is even terminated', () {
      final it = session();

      write(it, ['Serving at http://0.0.0.0:8080']);

      expect(it.state, ServiceState.serving);
    });

    test('goes back to generating when a reload rebuilds', () {
      final it = session();

      write(it, ['Serving at http://0.0.0.0:8080\n']);
      write(it, ['⠋ Generating server code...']);

      expect(it.state, ServiceState.generating);
    });

    test('is serving again once the reload comes back up', () {
      final it = session();

      write(it, [
        'Serving at http://0.0.0.0:8080\n',
        '⠋ Generating server code...',
        '\r✓ Generated server code\n',
        'Serving at http://0.0.0.0:8080\n',
      ]);

      expect(it.state, ServiceState.serving);
    });

    test('ordinary output does not move it', () {
      final it = session();

      write(it, ['a plain log line\n']);

      expect(it.state, ServiceState.starting);
    });
  });

  group('markExited', () {
    test('is stopped on a zero code', () {
      final it = session();

      write(it, ['Serving at http://0.0.0.0:8080\n']);
      it.markExited(0);

      expect(it.state, ServiceState.stopped);
      expect(it.exitCode, 0);
    });

    test('is crashed on a non-zero code', () {
      final it = session()..markExited(1);

      expect(it.state, ServiceState.crashed);
      expect(it.exitCode, 1);
    });

    test('crashing does not clear the session', () {
      // The usual cause is a compile error the developer is about to fix.
      // Dropping the lines would take the error away with it, and an empty
      // pane reads as the fleet going down.
      final it = session();

      write(it, ['Serving at http://0.0.0.0:8080\n']);
      write(it, [
        'orders.dart:12:5: Error: Expected an identifier\n',
      ], isError: true);
      it.markExited(255);

      expect(texts(it), [
        'Serving at http://0.0.0.0:8080',
        'orders.dart:12:5: Error: Expected an identifier',
      ]);
      expect(it.state, ServiceState.crashed);
    });

    test('keeps an unterminated last line, which is often the error', () {
      final it = session();

      write(it, ['Unhandled exception: Bad state'], isError: true);
      it.markExited(255);

      expect(texts(it), ['Unhandled exception: Bad state']);
    });

    test('drops a spinner frame that will never be redrawn', () {
      final it = session();

      write(it, ['⠋ Retrieving constructs...']);
      it.markExited(255);

      expect(it.lines, isEmpty);
    });

    test('output draining after the exit does not walk the state back', () {
      final it = session()..markExited(255);

      write(it, ['Serving at http://0.0.0.0:8080\n']);

      expect(it.state, ServiceState.crashed);
      expect(texts(it), ['Serving at http://0.0.0.0:8080']);
    });

    test('notifies its listeners', () {
      final it = session();
      var notifications = 0;
      it
        ..addListener(() => notifications++)
        ..markExited(0);

      expect(notifications, 1);
    });
  });
}
