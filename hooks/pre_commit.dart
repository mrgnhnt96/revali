import 'package:hooksman/hooksman.dart';
import 'package:path/path.dart' as p;

Hook main() {
  return PreCommitHook(
    tasks: [
      ReRegisterHooks(),
      ShellTask(
        include: [Glob('**.dart')],
        commands: (files) {
          return ['sip run barrel'];
        },
      ),
      SequentialTasks(
        tasks: [
          ParallelTasks(
            tasks: [
              ShellTask(
                include: [
                  Glob('packages/revali/lib/server/cli/models/**.dart'),
                ],
                commands: (files) {
                  return [
                    'cd packages/revali && dart run build_runner build --delete-conflicting-outputs',
                  ];
                },
              ),
              ShellTask(
                include: [Glob('packages/revali_construct/lib/models/**.dart')],
                commands: (files) {
                  return [
                    'cd packages/revali_construct && dart run build_runner build --delete-conflicting-outputs',
                  ];
                },
              ),
              ShellTask(
                include: [
                  Glob(
                    'revali_router/revali_router/lib/src/{route,router}/**.dart',
                  ),
                ],
                commands: (files) {
                  return [
                    'cd revali_router/revali_router && dart run build_runner build --delete-conflicting-outputs',
                  ];
                },
              ),
            ],
          ),
          ParallelTasks(
            tasks: [
              ShellTask(
                include: [Glob('**.dart')],
                exclude: [Glob('**.g.dart'), Glob('**/example/**.dart')],
                commands: (allFiles) {
                  if (allFiles.isEmpty) {
                    return [];
                  }

                  final files = allFiles.join(' ');
                  return [
                    'dart analyze --fatal-infos --fatal-warnings $files',
                    'dart format --set-exit-if-changed $files',
                  ];
                },
              ),
              ShellTask(
                include: [AllFiles()],
                commands: (files) {
                  final packages = <String>{};

                  for (final file in files) {
                    if (!file.contains('${p.separator}lib')) {
                      continue;
                    }

                    if (file.contains('test_suite')) {
                      continue;
                    }

                    final packagePath = file.split('${p.separator}lib').first;
                    packages.add(packagePath);
                  }
                  // Deliberately not `sip test`, for two separate reasons.
                  //
                  // It under-reports failures: in
                  // test_suite/constructs/revali_server/access_control it
                  // exits 0 reporting "40 passed, 0 failed" while `dart test`
                  // exits 1 with 3 failures.
                  //
                  // And it ignores `dart_test.yaml` tag skips. In
                  // packages/revali_redis, `dart test` reports "+50 ~1" with
                  // the @Tags(['integration']) suite skipped, while `sip test`
                  // runs all 62 -- so this hook used to run tests that need a
                  // Redis server on machines that have none, which blocked
                  // commits outright.
                  //
                  // run_all_tests.sh uses `dart test`, recurses into nested
                  // packages, and fails when it discovers nothing to run.
                  return [
                    for (final package in packages)
                      './scripts/run_all_tests.sh --path $package',
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
