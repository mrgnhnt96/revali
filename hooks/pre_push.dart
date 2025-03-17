import 'package:hooksman/hooksman.dart';

Hook main() {
  return Hook(
    diffArgs: const ['@{u}', 'HEAD'],
    tasks: [
      ShellTask.always(
        commands: (files) => ['sip run barrel --set-exit-if-changed'],
      ),
      ShellTask.always(
        commands: (files) {
          const test = 'sip test --recursive --bail --concurrent';
          return [
            'cd constructs && $test',
            'cd packages && $test',
            'cd revali_router && $test',
          ];
        },
      ),
      ShellTask.always(
        commands: (files) => ['sip run test-suite'],
      ),
      ShellTask(
        include: [AllFiles()],
        commands: (files) => ['dart format $files --set-exit-if-changed'],
      ),
      ShellTask(
        include: [AllFiles()],
        commands: (files) {
          final nonGenGlob = Glob('**.g.dart');
          final nonGeneratedFiles = files.where((e) => !nonGenGlob.matches(e));
          return ['dart analyze ${nonGeneratedFiles.join(' ')}'];
        },
      ),
    ],
  );
}
