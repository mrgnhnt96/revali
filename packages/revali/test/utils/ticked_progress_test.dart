@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:revali/services/service_plan.dart';
import 'package:test/test.dart';

/// Runs the probe fixture as a child process and returns what it wrote.
///
/// A child rather than an in-process call, because the claim is about bytes on
/// a pipe: a `TickedProgress` writes from a sidecar isolate straight to the
/// process's `stdout`, which no in-process capture can see.
Future<String> runProbe(String impl, String mode) async {
  final process = await Process.start('dart', [
    'run',
    'test/utils/fixtures/progress_probe.dart',
    impl,
    mode,
  ], workingDirectory: Directory.current.path);

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
int distinctFrames(String output) =>
    _frames.where(output.contains).length;

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

    test('matches what mason_logger writes, so `revali up` still reads it',
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
    });

    test('the frame reads as unfinished to a `revali up` pane', () async {
      final output = await runProbe('ticked', 'block');

      // `ServiceSession` decides a service is generating by finding a braille
      // glyph at the head of an unterminated line. A plain
      // `Generating server code...` would leave every row stuck on `starting`.
      final firstLine = output.split('\n').first;

      expect(isUnfinished(lastFrame(firstLine.split('\r').first)), isTrue);
    });
  });
}
