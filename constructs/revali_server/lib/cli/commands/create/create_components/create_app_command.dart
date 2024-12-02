import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:change_case/change_case.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali_server/cli/commands/create/mixins/create_command_mixin.dart';

class CreateAppCommand extends Command<int> with CreateCommandMixin {
  CreateAppCommand({
    required this.fs,
    required this.logger,
  }) {
    argParser
      ..addOption(
        'flavor',
        abbr: 'n',
        help: 'The flavor of the app',
        valueHelp: 'flavor',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite the app if it already exists',
        negatable: false,
      );
  }

  @override
  final Logger logger;

  @override
  String get description => 'creates a new app';

  @override
  String get name => 'app';

  @override
  final FileSystem fs;

  String? get flavorName => argResults?['flavor'] as String?;
  bool get force => argResults?['force'] as bool? ?? false;

  String content(String flavor) => '''
import 'package:revali_router/revali_router.dart';

@App(flavor: '$flavor')
final class ${flavor.toPascalCase()}App extends AppConfig {
  ${flavor.toPascalCase()}App() : super(host: 'localhost', port: 8080);
}
''';

  @override
  Future<int>? run() async {
    logger.detail('Running $name command');
    final rootDir = root;

    if (rootDir == null) {
      logger.warn('Failed to find pubspec.yaml');
      return 1;
    }

    final config = this.config;

    final routesPath = p.join(rootDir, 'routes');
    final appsPath = p.join(
      routesPath,
      config.createPaths.app,
    );

    var flavor = flavorName;

    while (flavor == null || flavor.isEmpty) {
      flavor = logger.prompt("What's the flavor of the ${green.wrap('app')}?");
    }

    final appPath = p.join(appsPath, '${flavor.toSnakeCase()}_app.dart');

    if (fs.file(appPath).existsSync()) {
      if (!force) {
        final overwrite = logger.confirm(
          red.wrap('App already exists, do you want to overwrite?'),
        );

        if (!overwrite) {
          return 0;
        }
      }
    }

    final progress = logger.progress('Creating app');

    try {
      fs.directory(appsPath).createSync(recursive: true);
      fs.file(appPath).writeAsStringSync(content(flavor));

      final relative = p.relative(appPath);

      progress.complete("${green.wrap('Created!')} ${darkGray.wrap(relative)}");
    } catch (e) {
      progress.fail();
      logger.detail('Failed to create app, $e');
      return 1;
    }

    return 0;
  }
}
