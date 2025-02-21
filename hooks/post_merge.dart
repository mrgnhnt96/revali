import 'package:hooksman/hooksman.dart';

Hook main() {
  return Hook(
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
