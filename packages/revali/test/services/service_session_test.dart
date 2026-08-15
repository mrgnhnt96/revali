import 'package:file/memory.dart';
import 'package:revali/services/ansi.dart';
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

  group('a colour-emitting child', () {
    // Captured from `mason_logger` with `ansiOutputEnabled` forced on, which
    // is what `revali up` gets once it sets REVALI_FORCE_ANSI on the child.
    // Byte for byte, including the `ESC[?7l` / `ESC[2K` each frame is wrapped
    // in -- those come out of `Progress` regardless of colour, and they are
    // the reason a frame's last character is not the one the child drew.
    const frames = [
      '\x1B[?7l\x1B[2K\r\x1B[92m⠙\x1B[0m Retrieving... \x1B[90m(83ms)\x1B[0m',
      '\x1B[?7l\x1B[2K\r\x1B[92m⠹\x1B[0m Retrieving... \x1B[90m(0.2s)\x1B[0m',
      '\x1B[?7l\x1B[2K\r\x1B[92m⠸\x1B[0m Retrieving... \x1B[90m(0.2s)\x1B[0m',
    ];

    test('its spinner still animates in place rather than stacking', () {
      final it = session();

      for (final (index, frame) in frames.indexed) {
        it.ingest(frame, isError: false);

        expect(
          it.lines,
          hasLength(1),
          reason: 'coloured frame ${index + 1} stacked instead of replacing',
        );
      }
    });

    test('its spinner still reads as a step in flight', () {
      final it = session();

      write(it, frames);

      expect(it.state, ServiceState.generating);
    });

    test('its resolved step still settles', () {
      final it = session();

      write(it, [
        ...frames,
        '\x1B[?7h\x1B[2K\r\x1B[92m✓\x1B[0m Retrieved \x1B[90m(0.3s)\x1B[0m\n',
      ]);

      expect(it.lines, hasLength(1));
      expect(it.state, ServiceState.generating);
    });

    test('the model keeps what the child sent, escapes and all', () {
      // Parsing on the way in would leave nothing for a renderer to colour
      // with. The session stores bytes; the pane decides what they mean.
      final it = session();

      write(it, ['\x1B[92mServing at http://0.0.0.0:8080\x1B[0m\n']);

      expect(texts(it), ['\x1B[92mServing at http://0.0.0.0:8080\x1B[0m']);
    });

    test('every state marker still fires through the colour', () {
      // The substring matches in `_note` were written for a child that
      // already coloured *some* lines. Turning colour on for all of them adds
      // an escape prefix to the rest, so each marker is re-proved here
      // against the bytes `mason_logger` actually writes for it: `success` in
      // lightGreen, `err` in lightRed, `warn` in yellow *and* bold, which is
      // two SGR sequences before the first character of the marker.
      const coloured = {
        '\x1B[92mServing at http://0.0.0.0:8080\x1B[0m\n': ServiceState.serving,
        '\x1B[91mFailed to bind server: address in use\x1B[0m\n':
            ServiceState.failed,
        '\x1B[33m\x1B[1m[WARN] Dev server is still running\x1B[22m\x1B[0m\n':
            ServiceState.failed,
        '\x1B[91mServer process terminated unexpectedly with exit '
                'code: 255\x1B[0m\n':
            ServiceState.failed,
      };

      for (final MapEntry(key: line, value: expected) in coloured.entries) {
        expect(
          (session()..ingest(line, isError: true)).state,
          expected,
          reason: 'the marker in ${stripAnsi(line).trim()} stopped matching',
        );
      }
    });

    test('a clear-screen sequence does not settle as the child wrote it', () {
      // `revali dev`'s `_wipeOrDivide` prints this on every reload. The
      // sequence itself never reaches the pane — it becomes a divider, and on
      // an empty pane not even that — and the cursor-home behind it draws
      // nothing, so neither leaves the child's bytes behind.
      final it = session()
        ..ingest('\x1B[2J\x1B[0;0H\n', isError: false)
        ..ingest('after\n', isError: false);

      expect(it.state, ServiceState.starting);
      expect(texts(it), ['after']);
    });
  });

  group('a clear-screen from the child', () {
    // Not a request to throw anything away: `revali dev` writes this whenever
    // it redraws the screen it believes it owns, which is every reload and
    // every status board as well as `c`. The pane keeps the history and marks
    // the spot — see [kRedrawDivider].
    const clear = '\x1B[2J\x1B[0;0H';

    test('divides what the pane is showing instead of emptying it', () {
      final it = session();

      write(it, ['one\n', 'two\n', '$clear\n']);

      expect(texts(it), ['one', 'two', kRedrawDivider]);
    });

    test('the error behind a failed start survives a reload', () {
      // The whole reason this is a divider. A service fails to bind, the row
      // says `needs fix`, and `r` reloads it — which starts by clearing. The
      // line that explains the row has to still be in the pane afterwards, or
      // there is nothing on screen saying why anything is wrong.
      final it = session();

      write(it, [
        '⠋ Starting server...',
        '\rFailed to bind server: port 8080 already in use\n',
        'Dev server is still running\n',
      ]);

      expect(it.state, ServiceState.failed);

      write(it, ['$clear\n⠋ Reloading...', '\r✓ Reloaded (1.2s)\n']);

      expect(
        texts(it),
        containsAllInOrder([
          'Failed to bind server: port 8080 already in use',
          kRedrawDivider,
          '✓ Reloaded (1.2s)',
        ]),
      );
    });

    test('keeps what followed it in the same chunk', () {
      // It arrives *in* the stream, not beside it. `revali dev` clears and
      // reprints its status board in one breath, and both halves belong in the
      // pane — the board under the rule, what it replaced above it.
      final it = session();

      write(it, ['one\n', '$clear\n[READY]\nServing at http://0.0.0.0:8080\n']);

      expect(texts(it), [
        'one',
        kRedrawDivider,
        '[READY]',
        'Serving at http://0.0.0.0:8080',
      ]);
    });

    test('leaves a transient frame alone', () {
      // A divider does not claim the screen went away, so a spinner that was
      // mid-flight is still mid-flight and stays where the pane draws it.
      final it = session();

      write(it, ['settled\n', '⠋ Generating server code...', '\n$clear\n']);

      expect(texts(it), [
        'settled',
        kRedrawDivider,
        '⠋ Generating server code...',
      ]);
    });

    test('draws nothing on a pane with nothing above it to divide', () {
      // A service's very first status board arrives behind a clear, and a rule
      // across the top of an empty pane divides nothing from nothing.
      final it = session();

      write(it, ['$clear\n[READY]\n']);

      expect(texts(it), ['[READY]']);
    });

    test('two redraws with nothing between them draw one rule', () {
      final it = session();

      write(it, ['one\n', '$clear$clear\ntwo\n']);

      expect(texts(it), ['one', kRedrawDivider, 'two']);
    });

    test('does not fire on a cursor-home on its own', () {
      // `ESC[0;0H` means *put the cursor at the top*, which is a statement
      // about a screen the child keeps writing down. Reading it as a clear
      // would rule the pane off every time a child homed the cursor.
      final it = session();

      write(it, ['one\n', 'two\n', '\x1B[0;0H\n', 'three\n']);

      expect(texts(it), ['one', 'two', 'three']);
    });

    test('keeps what stood between two clears in one chunk', () {
      final it = session();

      write(it, ['one\n', '${clear}kept\n${clear}also kept\n']);

      // Compared stripped: the cursor-home rides on the front of each line
      // with no newline between them, and the session stores the bytes it was
      // given. It is the renderer that drops it, which is where dropping it
      // belongs — the pane is the thing with no cursor to home.
      expect(
        [for (final text in texts(it)) stripAnsi(text)],
        ['one', '── redraw ──', 'kept', '── redraw ──', 'also kept'],
      );
    });

    test('does not change what the row says the service is doing', () {
      // A redraw is about the screen. The service is still serving, and a row
      // that walked back to `starting` on every reload would say so.
      final it = session();

      write(it, ['Serving at http://0.0.0.0:8080\n', '$clear\n']);

      expect(it.state, ServiceState.serving);
    });

    test('does not eat the half-line the other stream is still writing', () {
      // stderr is mid-way through a line when stdout redraws. Dropping its
      // buffered half would splice the rest onto nothing and corrupt it.
      final it = session()
        ..ingest('half a line', isError: true)
        ..ingest('$clear\n', isError: false)
        ..ingest(' and the rest\n', isError: true);

      expect(texts(it), ['half a line and the rest']);
    });
  });

  group('clear', () {
    // What `c` does. The one thing that truly empties a pane, and it is driven
    // from this side — the child's own `ESC[2J` cannot be told apart from the
    // one it writes on every reload.
    test('empties the pane', () {
      final it = session();

      write(it, ['one\n', 'two\n']);
      it.clear();

      expect(it.lines, isEmpty);
    });

    test('takes the transient frames with it', () {
      final it = session()
        ..ingest('⠋ Generating server code...', isError: false)
        ..ingest('⠋ Compiling...', isError: true)
        ..clear();

      expect(it.lines, isEmpty);
    });

    test('resets the scroll position, so a stale anchor cannot blank it', () {
      final it = session(maxLines: 100);

      for (var i = 0; i < 60; i++) {
        it.ingest('line-$i\n', isError: false);
      }
      it.scrollBy(-20, viewport: 10);
      expect(it.isLive, isFalse);

      it.clear();

      expect(it.isLive, isTrue);
    });

    test('notifies its listeners', () {
      var notified = 0;
      session()
        ..ingest('one\n', isError: false)
        ..addListener(() => notified++)
        ..clear();

      expect(notified, 1);
    });

    test('does not change what the row says the service is doing', () {
      final it = session()
        ..ingest('Serving at http://0.0.0.0:8080\n', isError: false)
        ..clear();

      expect(it.state, ServiceState.serving);
    });

    test('leaves the half-line a stream is still writing', () {
      // Same rule as a redraw: dropping half a line would splice the rest onto
      // nothing when the next chunk lands.
      final it = session()
        ..ingest('half a line', isError: true)
        ..clear();

      expect(it.lines, isEmpty);

      it.ingest(' and the rest\n', isError: true);

      expect(texts(it), ['half a line and the rest']);
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

  group('a server that is down while `revali dev` stays up', () {
    /// The port collision as it reached the pane, one write at a time.
    ///
    /// Nothing exits here: `revali dev` keeps running on purpose so the
    /// developer can free the port and press `r`. The spinner is the
    /// `Starting server` progress, which the child never completes because
    /// the server never announces itself — so it goes on animating over the
    /// top of the error for as long as the service stays broken.
    const transcript = [
      '⠋ Starting server',
      '\r⠙ Starting server',
      'SocketException: Failed to create server socket (OS Error: Address ',
      'already in use, errno = 48), address = 0.0.0.0, port = 8081\n',
      'Server process terminated unexpectedly with exit code: 1\n',
      'Failed to bind server:\n',
      '[WARN] Dev server is still running. Fix the error above, then press r ',
      'to restart the server process.\n',
    ];

    test('the observed transcript lands in failed, not generating', () {
      final it = session();

      write(it, transcript);

      expect(it.state, ServiceState.failed);
    });

    test('is not crashed — nothing exited', () {
      // `markExited` is what sets `crashed`, and it never fires here. Reading
      // the two as one state would say the process is gone when it is sitting
      // there waiting to be told to try again.
      final it = session();

      write(it, transcript);

      expect(it.state, isNot(ServiceState.crashed));
      expect(it.exitCode, isNull);
    });

    test('the still-turning spinner does not walk it back', () {
      // The whole bug in one case: the progress the child was showing when
      // the bind failed is never completed, so frames keep arriving after the
      // error. Each one used to re-assert `generating`.
      final it = session();

      write(it, transcript);
      write(it, ['\r⠹ Starting server', '\r⠸ Starting server']);

      expect(it.state, ServiceState.failed);
    });

    test('a reload that comes back up reaches serving', () {
      // Pressing `r` restarts the server process. A one-way trip to `failed`
      // would leave a healthy service reading as broken for the rest of the
      // session.
      final it = session();

      write(it, transcript);
      write(it, [
        '⠋ Restarting server',
        '\r✓ Server started\n',
        'Serving at http://0.0.0.0:8081\n',
      ]);

      expect(it.state, ServiceState.serving);
    });

    test('and can fail again after that', () {
      final it = session();

      write(it, [...transcript, 'Serving at http://0.0.0.0:8081\n']);
      expect(it.state, ServiceState.serving);

      write(it, ['Server process terminated unexpectedly with exit code: 1\n']);
      expect(it.state, ServiceState.failed);
    });

    test('a colour-wrapped line still matches', () {
      // `logger.warn` prefixes and colours, so the line arrives with escapes
      // in front of the text and around the `r` in the middle of it.
      final it = session();

      const warning =
          '\x1B[33m[WARN] Dev server is still running. Fix the error above, '
          'then press \x1B[33mr\x1B[0m to restart the server.\x1B[0m\n';

      write(it, [warning]);

      expect(it.state, ServiceState.failed);
    });

    test('a replayed line indented by the handler still matches', () {
      // The dead server's own output is replayed two spaces in.
      final it = session();

      write(it, [
        'Server stdout (last 2 lines):\n',
        '  Failed to bind server:\n',
      ]);

      expect(it.state, ServiceState.failed);
    });

    test('each marker is enough on its own', () {
      const stillRunning =
          'Dev server is still running. Fix the error above, then press r to '
          'restart the server process.';
      const markers = [
        'Failed to bind server:',
        'Server process terminated unexpectedly with exit code: 1',
        stillRunning,
      ];

      for (final marker in markers) {
        final it = session();

        write(it, ['⠋ Starting server', '\n$marker\n']);

        expect(
          it.state,
          ServiceState.failed,
          reason: 'a transcript cut short at "$marker" missed the failure',
        );
      }
    });

    test('the process exiting after it still reads as crashed', () {
      // Hot reload off: the handler prints the same lines and then stops
      // `revali dev` too. The distinction stops applying, and the state has
      // to follow the process.
      final it = session();

      write(it, transcript);
      it.markExited(1);

      expect(it.state, ServiceState.crashed);
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

  group('the announced address', () {
    test('is null until the service says where it is listening', () {
      final it = session();
      write(it, ['⠋ Retrieving dependencies...\n', 'Building...\n']);

      expect(it.baseUrl, isNull);
    });

    test('is read off the serving line', () {
      final it = session();
      write(it, ['Serving at http://0.0.0.0:8080/api\n']);

      expect(it.baseUrl, 'http://0.0.0.0:8080/api');
    });

    test('is read through the colour the child wrapped it in', () {
      final it = session();
      write(it, ['\x1B[92mServing at http://0.0.0.0:8080/api\x1B[0m\n']);

      expect(it.baseUrl, 'http://0.0.0.0:8080/api');
    });

    test('carries the app prefix, which the port alone does not', () {
      // The reason it is read from the child at all: `revali up` assigns the
      // port and has no idea the app mounts itself under `/api`.
      final it = session();
      write(it, ['Serving at http://0.0.0.0:8080/api/v2\n']);

      expect(it.baseUrl, endsWith('/api/v2'));
    });

    test('survives a reload that has not re-announced yet', () {
      // The child clears and rebuilds. In the gap the old address is still the
      // best answer there is, and nearly always still the right one.
      final it = session();
      write(it, ['Serving at http://0.0.0.0:8080/api\n']);

      write(it, ['$kClearScreen\n', '⠋ Reloading...\n']);

      expect(it.baseUrl, 'http://0.0.0.0:8080/api');
    });

    test('moves when the child announces a different one', () {
      final it = session();
      write(it, ['Serving at http://0.0.0.0:8080/api\n']);
      write(it, ['Serving at http://0.0.0.0:8081/api\n']);

      expect(it.baseUrl, 'http://0.0.0.0:8081/api');
    });

    test('is not cleared by a serving line with no parsable address', () {
      // `serving` with no way to reach it is the state this avoids.
      final it = session();
      write(it, ['Serving at http://0.0.0.0:8080/api\n']);
      write(it, ['Serving at \n']);

      expect(it.baseUrl, 'http://0.0.0.0:8080/api');
    });

    test('is left alone by a clear, which only empties the screen', () {
      final it = session();
      write(it, ['Serving at http://0.0.0.0:8080/api\n']);

      it.clear();

      expect(
        it.baseUrl,
        'http://0.0.0.0:8080/api',
        reason: 'emptying the pane does not move the service',
      );
    });
  });

  group('the scroll position', () {
    /// Feeds [count] whole lines, one per write.
    void fill(ServiceSession it, int count, {int from = 0}) {
      for (var i = from; i < from + count; i++) {
        it.ingest('line-$i\n', isError: false);
      }
    }

    test('starts at the live end', () {
      final it = session();
      fill(it, 20);

      expect(it.isLive, isTrue);
      expect(it.scrollTop, isNull);
    });

    test('scrolling up leaves the live end and anchors the top row', () {
      final it = session();
      fill(it, 20);

      it.scrollBy(-3, viewport: 5);

      expect(it.isLive, isFalse);
      // 20 lines, a 5-row window: the last window starts at 15, and three
      // rows back from there is 12.
      expect(it.scrollTop, 12);
    });

    test('new output leaves an anchored position exactly where it was', () {
      final it = session();
      fill(it, 20);
      it.scrollBy(-3, viewport: 5);

      fill(it, 50, from: 20);

      expect(it.scrollTop, 12);
    });

    test('scrolling back onto the last window re-sticks', () {
      final it = session();
      fill(it, 20);
      it
        ..scrollBy(-3, viewport: 5)
        ..scrollBy(3, viewport: 5);

      expect(it.isLive, isTrue);
      expect(it.scrollTop, isNull);
    });

    test('cannot be scrolled past the oldest line kept', () {
      final it = session();
      fill(it, 20);

      it.scrollBy(-1000, viewport: 5);

      expect(it.scrollTop, 0);
    });

    test('a buffer that fits the pane has nowhere to scroll', () {
      final it = session();
      fill(it, 3);

      it.scrollBy(-10, viewport: 20);

      expect(it.isLive, isTrue);
    });

    test('eviction moves the anchor so the view does not drift', () {
      // A cap small enough to reach, so eviction is the thing under test
      // rather than a thing that happens after 500 lines.
      final it = session(maxLines: 10);
      fill(it, 10);

      it.scrollBy(-2, viewport: 4);
      expect(it.scrollTop, 4);

      // Two more lines evict two from the front, so the same *content* is now
      // two indices lower.
      fill(it, 2, from: 10);

      expect(it.scrollTop, 2);
      expect(
        it.lines[it.scrollTop!].text,
        'line-4',
        reason: 'the anchor must still name the line it was parked on',
      );
    });

    test('an anchor on the oldest line stops rather than going negative', () {
      final it = session(maxLines: 10);
      fill(it, 10);

      it.scrollBy(-1000, viewport: 4);
      expect(it.scrollTop, 0);

      fill(it, 5, from: 10);

      expect(it.scrollTop, 0);
    });

    test('scrollToLive resumes following', () {
      final it = session();
      fill(it, 20);
      it
        ..scrollBy(-3, viewport: 5)
        ..scrollToLive();

      expect(it.isLive, isTrue);
    });

    test('a clear resets it, so a stale anchor cannot blank the pane', () {
      final it = session();
      fill(it, 20);
      it
        ..scrollBy(-3, viewport: 5)
        ..clear();

      expect(it.isLive, isTrue);
      expect(it.lines, isEmpty);
    });

    test('a redraw from the child leaves it exactly where it was', () {
      // The reader scrolled back to read something, and the reason a reload no
      // longer wipes it is that they were going to read it. Snapping to the
      // live end would take it away by a different route.
      final it = session();
      fill(it, 20);
      it.scrollBy(-3, viewport: 5);
      final parked = it.scrollTop;

      it.ingest('\x1b[2Jrebuilding\n', isError: false);

      expect(it.isLive, isFalse);
      expect(it.scrollTop, parked);
      expect([for (final line in it.lines) line.text], contains('line-0'));
    });

    test('notifies its listeners when the position changes', () {
      final it = session();
      fill(it, 20);

      var notifications = 0;
      it
        ..addListener(() => notifications++)
        ..scrollBy(-3, viewport: 5);
      expect(notifications, 1);

      // Already there: nothing changed, so nothing is repainted.
      it.scrollToLive();
      expect(notifications, 2);

      it.scrollToLive();
      expect(notifications, 2);
    });

    test('a zero-height pane cannot be scrolled', () {
      final it = session();
      fill(it, 20);

      it.scrollBy(-3, viewport: 0);

      expect(it.isLive, isTrue);
    });
  });

  group('markRestarted', () {
    /// Settles [count] numbered lines, the way a chatty child would.
    void fill(ServiceSession it, int count) {
      for (var i = 0; i < count; i++) {
        it.ingest('line-$i\n', isError: false);
      }
    }

    test('empties the pane a new process is about to write into', () {
      final it = session();
      write(it, ['boot\n', 'Unhandled exception: boom\n']);
      it.markExited(1);

      expect(texts(it), isNotEmpty);

      it.markRestarted();

      expect(texts(it), isEmpty);
    });

    test('drops the dead process’s half-written tail as well', () {
      final it = session();

      // No newline: a line the dead child was part way through writing. `c`
      // deliberately keeps this, because the same stream will finish it. A
      // restart must not — the stream that would have finished it is gone, and
      // holding it splices a dead child's fragment onto the front of the new
      // child's first chunk.
      write(it, ['half a li']);
      it
        ..markExited(1)
        ..markRestarted()
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);

      expect(texts(it), ['Serving at http://0.0.0.0:8080/']);
    });

    test('holds each stream’s tail separately from the other', () {
      final it = session();
      write(it, ['out frag']);
      write(it, ['err frag'], isError: true);
      it
        ..markExited(1)
        ..markRestarted();

      write(it, ['fresh out\n']);
      write(it, ['fresh err\n'], isError: true);

      expect(texts(it), ['fresh out', 'fresh err']);
    });

    test('goes back to starting and forgets the exit code', () {
      final it = session()..markExited(1);

      expect(it.state, ServiceState.crashed);
      expect(it.isDead, isTrue);

      it.markRestarted();

      expect(it.state, ServiceState.starting);
      expect(it.isDead, isFalse);
      expect(it.exitCode, isNull);
    });

    test('lets the new process move the state again', () {
      // A session that still believed it had exited would drop every frame:
      // `_note` returns early while an exit code is recorded, so the row would
      // sit on `starting` however much the new child printed.
      final it = session()
        ..markExited(1)
        ..markRestarted()
        ..ingest('Serving at http://0.0.0.0:8080/\n', isError: false);

      expect(it.state, ServiceState.serving);
    });

    test('unfreezes the scroll', () {
      final it = session();
      fill(it, 40);
      it
        ..scrollBy(-10, viewport: 5)
        ..markExited(1);

      expect(it.isLive, isFalse);

      it.markRestarted();

      expect(
        it.isLive,
        isTrue,
        reason:
            'an anchor into a buffer that no longer exists draws a blank '
            'pane, which reads as the restart having failed',
      );
    });

    test('keeps the address the service announced', () {
      final it = session()
        ..ingest('Serving at http://0.0.0.0:8080/api\n', isError: false)
        ..markExited(1)
        ..markRestarted();

      expect(
        it.baseUrl,
        'http://0.0.0.0:8080/api',
        reason:
            'the port does not move across a restart, and the new child '
            're-announces and overwrites this in a moment anyway',
      );
    });

    test('tells the pane it changed', () {
      final it = session()..markExited(1);

      var notifications = 0;
      it
        ..addListener(() => notifications++)
        ..markRestarted();

      expect(notifications, 1);
    });
  });
}
