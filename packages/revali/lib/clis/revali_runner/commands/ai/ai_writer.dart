import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

void writeAiFile({
  required FileSystem fs,
  required Logger logger,
  required String path,
  required String contents,
  required bool force,
}) {
  final file = fs.file(path);

  if (file.existsSync() && !force) {
    logger.info(
      'Skipped ${darkGray.wrap(p.relative(path))} (use --force to overwrite)',
    );
    return;
  }

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  logger.info('${green.wrap('Created')} ${darkGray.wrap(p.relative(path))}');
}
