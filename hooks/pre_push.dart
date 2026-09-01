import 'package:hooksman/hooksman.dart';

Hook main() {
  return PrePushHook(
    tasks: [
      ShellTask.always(
        name: 'Barrel',
        commands: (files) => ['sip run barrel --set-exit-if-changed'],
      ),
      SequentialTasks(
        name: 'Test Suite',
        tasks: [
          ShellTask.always(
            name: 'Generate Test Suite',
            commands: (files) => [
              'sip run test-suite --gen-only',
              'sleep 1',
              'cd test_suite && dart pub get',
            ],
          ),
          ShellTask.always(
            name: 'Verify Generated Server',
            commands: (files) {
              // The generate step above walks the hand-written
              // `test-suite:revali_server` list in scripts.yaml. A suite that
              // exists on disk but was never added to that list is invisible
              // to it -- which is how lifecycle/, messaging/ and
              // worker_isolates/ reached main with no generated server and
              // tests that could not compile.
              //
              // This script discovers packages by looking for `routes/`
              // instead, so the list cannot be the thing that decides what
              // gets checked. `--generate-only` because 'Run All Tests' below
              // already runs the suite.
              return ['./scripts/verify_generated_server.sh --generate-only'];
            },
          ),
          ParallelTasks(
            exclude: [Glob('**/example/**.dart')],
            tasks: [
              ShellTask.always(
                name: 'Run All Tests',
                commands: (files) {
                  // Not `sip test --recursive`. From the repo root that ran
                  // zero tests and exited 0, and even inside a package it
                  // under-reports: in
                  // test_suite/constructs/revali_server/access_control,
                  // `dart test` exits 1 with 3 failures while `sip test`
                  // exits 0 reporting "40 passed, 0 failed". A gate that
                  // cannot go red is not a gate.
                  //
                  // The script runs `dart test` per package and also fails
                  // if fewer packages ran than expected, so "discovered
                  // nothing" can never look like "everything passed".
                  return ['./scripts/run_all_tests.sh'];
                },
              ),
              ShellTask.always(
                name: 'Analyze',
                commands: (files) {
                  final nonGenGlob = Glob('**.g.dart');
                  final nonGeneratedFiles = files.where(
                    (e) => !nonGenGlob.matches(e),
                  );
                  return ['dart analyze ${nonGeneratedFiles.join(' ')}'];
                },
              ),
              ShellTask.always(
                name: 'Format',
                commands: (files) {
                  final dartFiles = files.where((e) => e.endsWith('.dart'));

                  if (dartFiles.isEmpty) {
                    return [];
                  }

                  return [
                    'dart format ${dartFiles.join(' ')} --set-exit-if-changed',
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
