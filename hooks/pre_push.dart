import 'package:hooksman/hooksman.dart';

Hook main() {
  return PrePushHook(
    tasks: [
      ShellTask.always(
        name: 'Barrel',
        commands: (files) => ['sip run barrel --set-exit-if-changed'],
      ),
      SequentialTasks.always(
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
            include: [Glob('**.dart')],
            exclude: [Glob('**/example/**.dart')],
            tasks: [
              ShellTask.always(
                name: 'Run All Tests',
                commands: (files) {
                  return ['sip test --recursive --bail --concurrent'];
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
                  if (files.isEmpty) {
                    return [];
                  }

                  return [
                    'dart format ${files.join(' ')} --set-exit-if-changed',
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
