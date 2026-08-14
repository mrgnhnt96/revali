@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:revali/utils/ticked_progress.dart';
import 'package:test/test.dart';

/// Runs the probe fixture as a child process and returns what it wrote.
///
/// A child rather than an in-process call, because the claim is about bytes on
/// a pipe: a `TickedProgress` writes from a sidecar isolate straight to the
/// process's `stdout`, which no in-process capture can see.
Future<String> runProbe(
  String impl,
  String mode, {
  Map<String, String> environment = const {},
}) async {
  final process = await Process.start(
    'dart',
    ['run', 'test/utils/fixtures/progress_probe.dart', impl, mode],
    workingDirectory: Directory.current.path,
    environment: environment,
  );

  final out = process.stdout.transform(utf8.decoder).join();
  await process.exitCode;

  return out;
}

/// The braille glyphs the spinner cycles through, taken from the set
/// `service_plan.dart` already matches on so the two cannot drift.
const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

/// How many *distinct* spinner glyphs appear anywhere in [output].
///
/// Distinct rather than total: a frozen spinner still writes, it just writes
/// the same glyph forever. Counting writes would call that animation.
int distinctFrames(String output) => _frames.where(output.contains).length;

void main() {
  group('while the main isolate is blocked', () {
    test('a sidecar-driven spinner keeps advancing', () async {
      final output = await runProbe('ticked-on', 'block');

      printOnFailure(jsonEncode(output));

      // 1200ms at 80ms a frame is 15 ticks, so all ten glyphs should appear.
      // Asserting more than half leaves room for a loaded machine without
      // letting a frozen spinner through.
      expect(
        distinctFrames(output),
        greaterThan(5),
        reason: 'the sidecar owns the timer, so a blocked main cannot stop it',
      );
    });

    test('a main-isolate spinner freezes — the control', () async {
      final output = await runProbe('main-timer', 'block');

      printOnFailure(jsonEncode(output));

      // This is what `mason_logger` does when it has a terminal, and it is
      // why this leaf exists. If this ever advances, the test above has
      // stopped proving anything and the sidecar is no longer earning itself.
      expect(
        distinctFrames(output),
        1,
        reason: 'Timer.periodic cannot fire on an isolate that never yields',
      );
    });
  });

  test('a main-isolate spinner does advance when main is free', () async {
    final output = await runProbe('main-timer', 'idle');

    printOnFailure(jsonEncode(output));

    // Without this, the control above would pass just as well against a
    // spinner that never animated at all.
    expect(distinctFrames(output), greaterThan(5));
  });

  group('with no terminal', () {
    test('output stays plain and un-animated', () async {
      final output = await runProbe('ticked', 'block');

      printOnFailure(jsonEncode(output));

      expect(distinctFrames(output), 1, reason: 'one static frame, no more');
      expect(output, isNot(contains('\x1b')), reason: 'no ANSI on a pipe');
      expect(output, startsWith('⠋ working...'));
      expect(output, endsWith('\n'));
    });

    test(
      'matches what mason_logger writes, so `revali up` still reads it',
      () async {
        final mason = await runProbe('mason', 'block');
        final ticked = await runProbe('ticked', 'block');

        printOnFailure('mason:  ${jsonEncode(mason)}');
        printOnFailure('ticked: ${jsonEncode(ticked)}');

        // The elapsed time differs run to run, so compare the shape rather than
        // the bytes: the leading static frame, and the resolved line after the
        // carriage return.
        String shape(String output) =>
            output.replaceAll(RegExp(r'\(\d+(\.\d+)?m?s\)'), '(TIME)');

        expect(shape(ticked), shape(mason));
      },
    );

    test('the frame reads as unfinished to a `revali up` pane', () async {
      final output = await runProbe('ticked', 'block');

      // `ServiceSession` decides a service is generating by finding a braille
      // glyph at the head of an unterminated line. A plain
      // `Generating server code...` would leave every row stuck on `starting`.
      final firstLine = output.split('\n').first;

      expect(isUnfinished(lastFrame(firstLine.split('\r').first)), isTrue);
    });
  });

  group('with no terminal but a parent rendering the frames', () {
    // What `revali up` gives a child: stdout is a pipe, and the parent has
    // said it is drawing a pane out of what comes down it.
    const forced = {kForceAnsiEnvVar: '1'};

    test('the spinner animates anyway', () async {
      final output = await runProbe('ticked', 'block', environment: forced);

      printOnFailure(jsonEncode(output));

      // The whole of the sidecar fix was inert under `revali up` until this
      // passed: `progressCanAnimate` asked `stdout.hasTerminal`, a pipe said
      // no, and the pane redrew one frozen frame for the length of a build.
      expect(
        distinctFrames(output),
        greaterThan(5),
        reason: 'the handshake says a pane is redrawing these in place',
      );
    });

    test('and its frames carry the colour the pane renders', () async {
      final output = await runProbe('ticked', 'block', environment: forced);

      printOnFailure(jsonEncode(output));

      // Painted from the sidecar isolate, where the zone value `runRevali`
      // set does not reach — so this fails unless the answer is carried
      // across the spawn. 92 is `lightGreen`, which is what the pane's parser
      // maps to the spinner's colour.
      expect(output, contains('\x1B[92m'));
    });

    test('a chunk of it still reads as one animating line to a pane', () async {
      final output = await runProbe('ticked', 'block', environment: forced);

      final session = ServiceSession(
        ServicePlan(
          service: RevaliService(
            name: 'orders',
            directory: MemoryFileSystem().directory('/svc/orders')
              ..createSync(recursive: true),
            relativePath: 'svc/orders',
          ),
          port: 8080,
          label: 'orders',
        ),
      );

      // The frames, cut just before the carriage return that the finished
      // line was drawn over — which is the state the pane is in for the whole
      // of a build, and the only state in which any of this matters.
      final resolved = output.indexOf('✓');
      expect(resolved, isNonNegative, reason: 'the probe never completed');
      final animating = output.substring(0, output.lastIndexOf('\r', resolved));

      // The point of animating at all. Fed the real bytes, the pane must show
      // one line that keeps changing — not one line per frame, and not a row
      // stuck on `starting` because the glyph got lost in the escapes.
      session.ingest(animating, isError: false);

      expect(session.lines, hasLength(1));
      expect(session.state, ServiceState.generating);
    });

    test('with neither, nothing animates — CI keeps its plain log', () async {
      // The branch nobody runs by hand. `progressCanAnimate` is an `or`, and
      // an `or` that has learned to say yes to one input is one edit away
      // from saying yes to none.
      final output = await runProbe('ticked', 'block');

      printOnFailure(jsonEncode(output));

      expect(distinctFrames(output), 1);
      expect(output, isNot(contains('\x1B')));
    });
  });

  group('canAnimateProgress', () {
    // `progressCanAnimate` reads two things a test process cannot arrange for
    // itself: whether its own stdout is a terminal, and an environment fixed
    // at startup. This is the same decision with both handed in.
    test('a terminal of our own animates', () {
      expect(canAnimateProgress(hasTerminal: true, forcedAnsi: false), isTrue);
    });

    test('the handshake animates without one', () {
      expect(canAnimateProgress(hasTerminal: false, forcedAnsi: true), isTrue);
    });

    test('neither stays plain', () {
      expect(
        canAnimateProgress(hasTerminal: false, forcedAnsi: false),
        isFalse,
      );
    });
  });

  group('ansiForcedByParent', () {
    test('reads the handshake the parent sets', () {
      expect(ansiForcedByParent({kForceAnsiEnvVar: '1'}), isTrue);
    });

    test('an unset variable is not the handshake', () {
      expect(ansiForcedByParent(const {}), isFalse);
    });

    test('only `1` is, so an inherited leftover cannot half-mean it', () {
      // Both ends write `1`. Anything else reaching a child came from
      // somewhere that is not `revali up`, and guessing at it would turn a
      // stray `REVALI_FORCE_ANSI=0` into escape sequences in a build log.
      expect(ansiForcedByParent({kForceAnsiEnvVar: '0'}), isFalse);
      expect(ansiForcedByParent({kForceAnsiEnvVar: 'true'}), isFalse);
    });
  });
}
