@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:revali/services/ansi.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:revali/services/service_session.dart';
import 'package:test/test.dart';

/// Runs the status-board probe as a child process and returns its stdout.
///
/// A child rather than an in-process call for the same reason
/// `ticked_progress_test.dart` uses one: the claim is about bytes on a pipe,
/// and `mason_logger` writes to the process's `stdout` where no in-process
/// capture can see them.
Future<String> runProbe({
  Map<String, String> environment = const {},
  List<String> args = const [],
}) async {
  final process = await Process.start(
    'dart',
    ['run', 'test/handlers/fixtures/status_board_probe.dart', ...args],
    workingDirectory: Directory.current.path,
    environment: environment,
  );

  final out = process.stdout.transform(utf8.decoder).join();
  await process.exitCode;

  return out;
}

ServiceSession session() => ServiceSession(
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

void main() {
  group('the status board is `revali dev`\'s output, not the server\'s', () {
    test(
      'it is coloured by the handshake, in the process that prints it',
      () async {
        final output = await runProbe(
          environment: const {kForceAnsiEnvVar: '1'},
        );

        printOnFailure(jsonEncode(output));

        // There is no server process anywhere in this probe, and these bytes
        // still come out coloured. `[READY]`, the timestamp beside it and the
        // key hints below it are composed by `printStatusBoard` — as is
        // `Serving at ...`, which the server prints plainly and `revali dev`
        // re-prints through `logger.success`, and as is the route table, from
        // the same method a few lines further down.
        expect(output, contains('\x1B[90m[READY]\x1B[0m'));
        expect(output, contains('\x1B[33m'), reason: 'the yellow timestamp');
      },
    );

    test(
      'and stays plain without it, so a redirected log is unchanged',
      () async {
        final output = await runProbe();

        printOnFailure(jsonEncode(output));

        expect(output, contains('[READY]'));
        expect(
          output,
          isNot(matches(RegExp(r'\x1B\[[0-9;]*m'))),
          reason: 'no SGR anywhere: this is the shape CI redirects to a file',
        );

        // The clear is *not* part of that decision, and comes out either way —
        // `_wipeOrDivide` writes it unconditionally. Pinned rather than
        // corrected: it is the flat path's business, not this leaf's, and a
        // reader who finds `[2J[0;0H` in a build log should find it here too.
        expect(output, contains(kClearScreen));
      },
    );
  });

  group('the handshake has to be made on the isolate that prints', () {
    // Why the board was white under `revali up` while every check said it
    // should not be. `revali dev` is two programs: the `revali` CLI, and the
    // constructs entrypoint it starts with `Isolate.spawnUri`. Everything a
    // developer reads on the board is printed by the second one.
    //
    // The probe above was run on one isolate, so it could not see this, and
    // it passed — which is worth remembering when the next check passes.

    test('a forced zone does NOT reach an isolate spawned from it', () async {
      // The assumption that was false. `runRevali` forces the colour on and
      // this still comes out plain, because a zone value is a fact about an
      // isolate and `spawnUri` starts a new one.
      final output = await runProbe(
        environment: const {kForceAnsiEnvVar: '1'},
        args: const ['--spawn', '--naked'],
      );

      printOnFailure(jsonEncode(output));

      expect(output, contains('[READY]'));
      expect(
        output,
        isNot(matches(RegExp(r'\x1B\[[0-9;]*m'))),
        reason: 'the pane rendered exactly this, and drew it white',
      );
    });

    test('so the spawned isolate asks for itself, and is coloured', () async {
      // `runConstruct`'s half of the handshake, across the real boundary. It
      // can ask because the signal is an environment variable, and an
      // environment is process-wide where a zone is not.
      final output = await runProbe(
        environment: const {kForceAnsiEnvVar: '1'},
        args: const ['--spawn'],
      );

      printOnFailure(jsonEncode(output));

      expect(output, contains('\x1B[90m[READY]\x1B[0m'));
      expect(output, contains('\x1B[33m'), reason: 'the yellow timestamp');
    });

    test('and stays plain across it without the handshake', () async {
      // CI still gets a clean log, boundary or no boundary.
      final output = await runProbe(args: const ['--spawn']);

      printOnFailure(jsonEncode(output));

      expect(output, contains('[READY]'));
      expect(output, isNot(matches(RegExp(r'\x1B\[[0-9;]*m'))));
    });
  });

  group('the clear that `revali dev` sends before the board', () {
    test('is on the wire, ahead of the board it is clearing', () async {
      final output = await runProbe(environment: const {kForceAnsiEnvVar: '1'});

      printOnFailure(jsonEncode(output));

      // `_wipeOrDivide`, which is what `c` and every reload go through. The
      // cursor-home rides along behind it.
      expect(output, contains('$kClearScreen\x1B[0;0H'));
      expect(output.indexOf(kClearScreen), lessThan(output.indexOf('[READY]')));
    });

    test('rules the pane off and leaves the board that followed it', () async {
      final output = await runProbe(environment: const {kForceAnsiEnvVar: '1'});

      final it = session()
        ..ingest('an old line from before the clear\n', isError: false)
        ..ingest(output, isError: false);

      final texts = [for (final line in it.lines) stripAnsi(line.text)];

      printOnFailure(texts.toString());

      // Against the bytes the child really sends: what came before is still
      // there, with a rule under it, and the board that arrived in the same
      // chunk is below that.
      expect(
        texts,
        containsAllInOrder([
          'an old line from before the clear',
          stripAnsi(kRedrawDivider),
        ]),
      );
      expect(texts.any((text) => text.contains('[READY]')), isTrue);
      expect(
        texts.indexOf(stripAnsi(kRedrawDivider)),
        lessThan(texts.indexWhere((text) => text.contains('[READY]'))),
      );
    });
  });
}
