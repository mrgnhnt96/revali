import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:change_case/change_case.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali_server/cli/commands/create/mixins/create_command_mixin.dart';

abstract class CreateAComponentCommand extends Command<int>
    with CreateCommandMixin {
  CreateAComponentCommand({
    required this.fs,
    required this.logger,
  }) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite the file if it already exists',
      negatable: false,
    );
  }

  @override
  final Logger logger;

  @override
  final FileSystem fs;

  @override
  bool get force => argResults?['force'] as bool? ?? false;

  @override
  String get componentName => name;

  @override
  String get directory;

  @override
  FutureOr<int>? run() async {
    logger.detail('Running $name command');
    final rootDir = root;

    if (rootDir == null) {
      logger.warn('Failed to find pubspec.yaml');
      return 1;
    }

    final directoryPath = p.joinAll([rootDir, directory]);

    prompt();

    final appPath = p.join(directoryPath, fileName);

    if (fs.file(appPath).existsSync()) {
      if (!force) {
        final overwrite = logger.confirm(
          red.wrap(
            '${componentName.toTitleCase()} already exists, '
            'do you want to overwrite?',
          ),
        );

        if (!overwrite) {
          return 0;
        }
      }
    }

    final progress = logger.progress('Creating ${componentName.toLowerCase()}');

    try {
      fs.directory(directoryPath).createSync(recursive: true);
      fs.file(appPath).writeAsStringSync(content());

      final relative = p.relative(appPath);

      progress.complete("${green.wrap('Created!')} ${darkGray.wrap(relative)}");
    } catch (e) {
      progress.fail();
      logger.detail('Failed to create ${componentName.toLowerCase()}, $e');
      return 1;
    }

    return 0;
  }
}
