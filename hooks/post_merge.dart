import 'package:hooksman/hooksman.dart';

Hook main() {
  return AnyHook(
    tasks: [
      ShellTask.always(
        commands: (files) {
          return [
            'sip pub get --recursive --no-version-check --precompile',
          ];
        },
      ),
    ],
  );
}
