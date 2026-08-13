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
