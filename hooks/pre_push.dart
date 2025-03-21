import 'package:hooksman/hooksman.dart';

Hook main() {
  return Hook(
    diffArgs: const ['@{u}', 'HEAD'],
    tasks: [
      ShellTask.always(
        commands: (files) => ['sip run barrel --set-exit-if-changed'],
      ),
      ParallelTasks.always(
        tasks: [
          ShellTask.always(
            commands: (files) {
              return [
                'cd constructs && sip test --recursive --bail --concurrent',
              ];
            },
          ),
          ShellTask.always(
            commands: (files) {
              return [
                'cd packages && sip test --recursive --bail --concurrent',
              ];
            },
          ),
          ShellTask.always(
            commands: (files) {
              return [
                'cd revali_router && sip test --recursive --bail --concurrent',
              ];
            },
          ),
        ],
      ),
      SequentialTasks.always(
        tasks: [
          ShellTask.always(
            commands: (files) => [
              'sip run test-suite',
            ],
          ),
          ParallelTasks.always(
            tasks: [
              ShellTask.always(
                commands: (files) {
                  final nonGenGlob = Glob('**.g.dart');
                  final nonGeneratedFiles =
                      files.where((e) => !nonGenGlob.matches(e));
                  return ['dart analyze ${nonGeneratedFiles.join(' ')}'];
                },
              ),
              ShellTask.always(
                commands: (files) =>
                    ['dart format $files --set-exit-if-changed'],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
