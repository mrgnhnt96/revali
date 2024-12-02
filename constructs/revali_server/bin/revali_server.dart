// ignore_for_file: avoid_print

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/revali_server_runner.dart';

Future<int> main(List<String> args) async {
  const fs = LocalFileSystem();
  final logger = Logger();

  final runner = RevaliServerRunner(
    fs: fs,
    logger: logger,
  );

  try {
    final exitCode = await runner.run(args);

    return exitCode ?? 0;
  } catch (_) {
    return 1;
  }
}
