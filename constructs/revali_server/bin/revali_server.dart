// ignore_for_file: avoid_print

import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/revali_server_runner.dart';

Future<int> main(List<String> providedArgs) async {
  final args = [...providedArgs];
  const fs = LocalFileSystem();
  final logger = Logger();

  if (args.contains('--loud')) {
    logger.level = Level.verbose;
  } else if (args.contains('--quiet')) {
    logger.level = Level.critical;
  }

  args
    ..remove('--loud')
    ..remove('--quiet');

  final runner = RevaliServerRunner(
    fs: fs,
    logger: logger,
  );

  try {
    final exitCode = await runner.run(args);

    return exitCode ?? 0;
  } catch (e) {
    logger
      ..err('An error occurred')
      ..err(e.toString());
    return 1;
  }
}
