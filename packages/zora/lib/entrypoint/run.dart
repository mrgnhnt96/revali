import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:zora/zora.dart';
import 'package:zora_construct/zora_construct.dart';

Future<int> run(
  List<String> args, {
  required List<ConstructMaker> constructs,
  required String path,
}) async {
  final fs = LocalFileSystem();

  final originalArgs = ZoraRunner.originalArgs;
  var isLoud = false;
  var isQuiet = false;
  if (originalArgs.contains('--loud')) {
    isLoud = true;
  } else if (originalArgs.contains('--quiet')) {
    isQuiet = true;
  }

  final logger = Logger(
    level: isLoud
        ? Level.verbose
        : isQuiet
            ? Level.error
            : Level.info,
  );

  final runner = ConstructRunner(
    fs: fs,
    constructs: constructs,
    rootPath: path,
    logger: logger,
  );

  final result = await runner.run(args);

  return result;
}
