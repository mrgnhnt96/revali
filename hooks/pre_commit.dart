import 'package:hooksman/hooksman.dart';
import 'package:path/path.dart' as p;

Hook main() {
  return Hook(
    tasks: [
      ReRegisterHooks(),
      ShellTask(
        include: [
          Glob('**.dart'),
        ],
        commands: (files) {
          return [
            'sip run barrel',
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
          return [
            for (final package in packages)
              'cd $package && sip test --recursive --bail',
          ];
        },
      ),
      ShellTask(
        include: [
          Glob('constructs/revali_server/lib/cli/models/**.dart'),
        ],
        commands: (files) {
          return [
            'cd constructs/revali_server && dart run build_runner build --delete-conflicting-outputs',
          ];
        },
      ),
      ShellTask(
        include: [
          Glob('packages/revali_construct/lib/models/**.dart'),
        ],
        commands: (files) {
          return [
            'cd packages/revali_construct && dart run build_runner build --delete-conflicting-outputs',
          ];
        },
      ),
      ShellTask(
        include: [
          Glob('revali_router/revali_router/lib/src/{route,router}/**.dart'),
        ],
        commands: (files) {
          return [
            'cd revali_router/revali_router && dart run build_runner build --delete-conflicting-outputs',
          ];
        },
      ),
      ShellTask(
        include: [
          Glob('**.dart'),
        ],
        exclude: [
          Glob('**.g.dart'),
          Glob('**/example/**.dart'),
        ],
        commands: (files) {
          return [
            'dart analyze --fatal-infos --fatal-warnings ${files.join(' ')}',
            'dart format --set-exit-if-changed ${files.join(' ')}',
          ];
        },
      ),
    ],
  );
}
