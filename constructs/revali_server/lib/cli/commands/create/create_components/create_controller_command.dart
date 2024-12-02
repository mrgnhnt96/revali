import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:change_case/change_case.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:revali_server/cli/commands/create/mixins/create_command_mixin.dart';

class CreateControllerCommand extends Command<int> with CreateCommandMixin {
  CreateControllerCommand({
    required this.fs,
    required this.logger,
  }) {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'The name of the controller',
        valueHelp: 'name',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite the controller if it already exists',
        negatable: false,
      );
  }

  @override
  final Logger logger;

  @override
  String get description => 'creates a new controller';

  @override
  String get name => 'controller';

  @override
  final FileSystem fs;

  String? get controllerName => argResults?['name'] as String?;
  bool get force => argResults?['force'] as bool;

  String content(String name) => '''
import 'package:revali_router/revali_router.dart';

@Controller('${name.toPathCase()}')
class ${name.toPascalCase()}Controller {
  const ${name.toPascalCase()}Controller();

  String handle() {
    return 'Hello world!';
  }
}
''';

  @override
  Future<int>? run() async {
    logger.detail('Running ${this.name} command');
    final rootDir = root;

    if (rootDir == null) {
      logger.warn('Failed to find pubspec.yaml');
      return 1;
    }

    final config = this.config;

    final routesPath = p.join(rootDir, 'routes');
    final controllersPath = p.join(
      routesPath,
      config.createPaths.controller,
    );

    var name = controllerName;

    while (name == null || name.isEmpty) {
      name =
          logger.prompt("What's the name of the ${green.wrap('controller')}?");
    }

    final controllerPath =
        p.join(controllersPath, '${name.toSnakeCase()}_controller.dart');

    if (fs.file(controllerPath).existsSync()) {
      if (!force) {
        final overwrite = logger.confirm(
          red.wrap('Controller already exists, do you want to overwrite?'),
        );

        if (!overwrite) {
          return 0;
        }
      }
    }

    final progress = logger.progress('Creating controller');

    try {
      fs.directory(controllersPath).createSync(recursive: true);
      fs.file(controllerPath).writeAsStringSync(content(name));

      final relative = p.relative(controllerPath);

      progress.complete("${green.wrap('Created!')} ${darkGray.wrap(relative)}");
    } catch (e) {
      progress.fail();
      logger.detail('Failed to create controller, $e');
      return 1;
    }

    return 0;
  }
}
