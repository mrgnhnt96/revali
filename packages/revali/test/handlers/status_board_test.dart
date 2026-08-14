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
Future<String> runProbe({Map<String, String> environment = const {}}) async {
  final process = await Process.start(
    'dart',
    ['run', 'test/handlers/fixtures/status_board_probe.dart'],
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

  group('the clear that `revali dev` sends before the board', () {
    test('is on the wire, ahead of the board it is clearing', () async {
      final output = await runProbe(environment: const {kForceAnsiEnvVar: '1'});

      printOnFailure(jsonEncode(output));

      // `_wipeOrDivide`, which is what `c` and every reload go through. The
      // cursor-home rides along behind it.
      expect(output, contains('$kClearScreen\x1B[0;0H'));
      expect(output.indexOf(kClearScreen), lessThan(output.indexOf('[READY]')));
    });

    test('empties the pane and leaves the board that followed it', () async {
      final output = await runProbe(environment: const {kForceAnsiEnvVar: '1'});

      final it = session()
        ..ingest('an old line from before the clear\n', isError: false)
        ..ingest(output, isError: false);

      final texts = [for (final line in it.lines) stripAnsi(line.text)];

      printOnFailure(texts.toString());

      // The whole of defect 3, against the bytes the child really sends: the
      // line from before is gone, and the board that arrived in the same
      // chunk is not.
      expect(texts, isNot(contains('an old line from before the clear')));
      expect(texts.any((text) => text.contains('[READY]')), isTrue);
    });
  });
}
