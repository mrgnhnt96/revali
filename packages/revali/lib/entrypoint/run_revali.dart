import 'dart:io';

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/revali_runner.dart';

void runRevali(List<String> args) {
  _run(args);
}

Future<void> _run(List<String> args) async {
  const fs = LocalFileSystem();

  var isLoud = false;
  var isQuiet = false;
  if (args.contains('--loud')) {
    isLoud = true;
  } else if (args.contains('--quiet')) {
    isQuiet = true;
  }

  final logger = Logger(
    level: isLoud
        ? Level.verbose
        : isQuiet
            ? Level.error
            : Level.info,
  );

  final runner = RevaliRunner(
    initialDirectory: fs.currentDirectory.path,
    fs: fs,
    logger: logger,
  );

  final result = await runner.run(args);

  exit(result);
}
