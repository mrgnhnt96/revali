import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:revali/revali.dart';
import 'package:revali_construct/revali_construct.dart';

Future<int> runConstruct(
  List<String> args, {
  required List<ConstructMaker> constructs,
  required String path,
}) async {
  const fs = LocalFileSystem();

  // `--root` is consumed by the construct kernel entrypoint / spawn caller;
  // ConstructRunner's arg parser must not see it.
  final filteredArgs = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == ConstructEntrypointHandler.rootArgName) {
      if (i + 1 < args.length) i++;
      continue;
    }
    filteredArgs.add(args[i]);
  }

  var isLoud = false;
  var isQuiet = false;
  if (filteredArgs.contains('--loud')) {
    isLoud = true;
  } else if (filteredArgs.contains('--quiet')) {
    isQuiet = true;
  }

  final logger = Logger(
    level: isLoud
        ? Level.verbose
        : isQuiet
        ? Level.error
        : Level.info,
  );

  const platform = LocalPlatform();

  final runner = ConstructRunner(
    fs: fs,
    constructs: constructs,
    rootPath: path,
    logger: logger,
    analyzer: Analyzer(
      fs: fs,
      find: const FindImpl(
        platform: platform,
        fs: fs,
        startProcess: processToDetails,
      ),
      platform: platform,
      logger: logger,
    ),
  );

  final result = await runner.run(filteredArgs);

  return result;
}
