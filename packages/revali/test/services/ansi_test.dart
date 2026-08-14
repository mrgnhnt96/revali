import 'dart:convert';
import 'dart:io' as io;

// `overrideAnsiOutput` and `ansiOutputEnabled` are `package:io`'s, re-exported
// by `mason_logger`. Taken from here on purpose: what these tests assert is
// that the override reaches `mason_logger`'s colouring, which is only true
// while the two share one copy of `package:io`.
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_plan.dart';
import 'package:test/test.dart';

void main() {
  group('the premise [kForceAnsiEnvVar] exists for', () {
    // Two facts about someone else's packages that the whole of `revali up`'s
    // colour rests on. Asserted rather than trusted, because if either moves
    // the failure is silent: the pane keeps rendering perfectly and there is
    // simply no colour in what reaches it, which reads as a bug in the
    // renderer and not in the handshake.

    test('a child writing to a pipe emits no colour at all', () {
      // `dart test` pipes this process's output, so this test stands exactly
      // where a service spawned by `revali up` stands.
      expect(io.stdout.supportsAnsiEscapes, isFalse);
      expect(ansiOutputEnabled, isFalse);
      expect(lightGreen.wrap('X'), 'X');
    });

    test('overrideAnsiOutput is what turns it back on', () {
      overrideAnsiOutput(true, () {
        expect(ansiOutputEnabled, isTrue);
        expect(lightGreen.wrap('X'), '\x1B[92mX\x1B[0m');
      });
    });

    test('and it reaches the frames a Progress writes from a timer', () async {
      // The frames matter more than the plain writes: they are written from a
      // `Timer.periodic`, which paints in the zone it was *created* in. Wrap
      // the wrong scope and every ordinary line is coloured while the spinner
      // -- the thing the pane most needs -- stays plain.
      final capture = _CaptureStdout();

      await io.IOOverrides.runZoned(
        () => overrideAnsiOutput(true, () async {
          final progress = Logger().progress('Retrieving');
          await Future<void>.delayed(const Duration(milliseconds: 200));
          progress.complete('Retrieved');
        }),
        stdout: () => capture,
      );

      expect(capture.text, contains('\x1B[92m'));
      expect(
        parseAnsi(
          capture.text,
        ).any((span) => span.color == 92 && isUnfinished(span.text)),
        isTrue,
        reason: 'a spinner glyph should arrive wearing lightGreen',
      );
    });
  });
  group('parseAnsi', () {
    test('leaves a line with no escapes as one span', () {
      expect(parseAnsi('Retrieved constructs'), [
        const AnsiSpan('Retrieved constructs'),
      ]);
    });

    test('reads a foreground colour off an SGR sequence', () {
      expect(parseAnsi('\x1B[32mgreen\x1B[0m plain'), [
        const AnsiSpan('green', color: 32),
        const AnsiSpan(' plain'),
      ]);
    });

    test('reads the bright foreground range mason_logger actually uses', () {
      // `lightGreen` is 92 and `darkGray` is 90 -- between them most of what a
      // `Progress` line is made of. A parser that stopped at 37 would drop the
      // colour off nearly every line a service prints.
      expect(parseAnsi('\x1B[92m✓\x1B[0m done \x1B[90m(0.3s)\x1B[0m'), [
        const AnsiSpan('✓', color: 92),
        const AnsiSpan(' done '),
        const AnsiSpan('(0.3s)', color: 90),
      ]);
    });

    test('carries bold and dim, and lets 22 clear just those', () {
      expect(parseAnsi('\x1B[33m\x1B[1m[WARN] x\x1B[22m\x1B[0m'), [
        const AnsiSpan('[WARN] x', color: 33, bold: true),
      ]);

      expect(parseAnsi('\x1B[31m\x1B[2mdim\x1B[22mloud'), [
        const AnsiSpan('dim', color: 31, dim: true),
        const AnsiSpan('loud', color: 31),
      ]);
    });

    test('treats 39 as the default foreground and 0 as a full reset', () {
      expect(parseAnsi('\x1B[31m\x1B[1mred\x1B[39mbold\x1B[0mplain'), [
        const AnsiSpan('red', color: 31, bold: true),
        const AnsiSpan('bold', bold: true),
        const AnsiSpan('plain'),
      ]);
    });

    test('merges neighbouring runs that would paint identically', () {
      // A redundant reset is not a reason to hand the renderer two spans.
      expect(parseAnsi('one\x1B[0mtwo'), [const AnsiSpan('onetwo')]);
    });

    test('drops every escape sequence that is not colour', () {
      // Exactly what `revali dev` prints from `_wipeOrDivide`, and what
      // `mason_logger` brackets each spinner frame with. These are
      // instructions to a terminal that owns its screen; this pane does not.
      expect(parseAnsi('\x1B[2J\x1B[0;0Hcleared'), [const AnsiSpan('cleared')]);
      expect(parseAnsi('\x1B[?7l\x1B[2Kframe\x1B[?7h'), [
        const AnsiSpan('frame'),
      ]);
      expect(parseAnsi('\x1B[1;5Hmoved\x1B[K'), [const AnsiSpan('moved')]);
    });

    test('does not read a private-marker sequence as a colour', () {
      // `ESC[?7l` shares its digits with SGR 7. Reading them would invent a
      // style nobody asked for; the `?` is what says it is not SGR at all.
      expect(parseAnsi('\x1B[?25lx'), [const AnsiSpan('x')]);
      expect(parseAnsi('\x1B[?32mx'), [const AnsiSpan('x')]);
    });

    test('drops a sequence the chunk boundary cut in half', () {
      // Chunks split wherever the pipe felt like splitting them. Half an
      // escape is not a character anyone meant to see.
      expect(parseAnsi('done\x1B'), [const AnsiSpan('done')]);
      expect(parseAnsi('done\x1B[3'), [const AnsiSpan('done')]);
    });

    test('leaves nothing behind for a line that is only escapes', () {
      expect(parseAnsi('\x1B[2J\x1B[0;0H'), isEmpty);
    });
  });

  group('stripAnsi', () {
    test('returns the visible text and nothing else', () {
      expect(
        stripAnsi('\x1B[92m⠙\x1B[0m Retrieving... \x1B[90m(83ms)\x1B[0m'),
        '⠙ Retrieving... (83ms)',
      );
      expect(stripAnsi('\x1B[2J\x1B[0;0H'), '');
    });

    test('leaves a plain line untouched', () {
      expect(stripAnsi('✓ Retrieved constructs'), '✓ Retrieved constructs');
    });
  });
}

/// A stdout that keeps what was written to it and claims to support colour.
///
/// `supportsAnsiEscapes` is true so the capture cannot be the thing that turns
/// colour off — the point of the test above it is which *zone* the write
/// happened in, and a fake that answered false would pass it for the wrong
/// reason.
class _CaptureStdout implements io.Stdout {
  final _buffer = StringBuffer();

  String get text => '$_buffer';

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer
    ..write(object)
    ..write('\n');

  @override
  bool get supportsAnsiEscapes => true;

  @override
  bool get hasTerminal => true;

  @override
  int get terminalColumns => 80;

  @override
  int get terminalLines => 24;

  @override
  Encoding encoding = utf8;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
