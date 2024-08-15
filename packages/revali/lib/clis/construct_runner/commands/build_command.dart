import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/construct_runner/generator/construct_generator.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/models/construct_maker.dart';

class BuildCommand extends Command<int> with DirectoriesMixin {
  BuildCommand({
    required this.rootPath,
    required this.constructs,
    required this.fs,
    required this.logger,
    RoutesHandler? routesHandler,
  }) : routesHandler = routesHandler ??
            RoutesHandler(
              fs: fs,
              rootPath: rootPath,
            ) {
    argParser
      ..addOption(
        'flavor',
        abbr: 'f',
        help: 'The flavor to use for the app (case-sensitive)',
      )
      ..addMultiOption(
        'dart-define',
        help: 'Additional key-value pairs that will be available as constants.',
        valueHelp: 'BASE_URL=https://api.example.com',
      )
      ..addMultiOption(
        'dart-define-from-file',
        help: 'A file containing additional key-value '
            'pairs that will be available as constants.',
        valueHelp: '.env',
      );
  }

  final RoutesHandler routesHandler;
  final List<ConstructMaker> constructs;
  final String rootPath;
  @override
  final FileSystem fs;
  final Logger logger;

  @override
  String get name => 'build';

  @override
  String get description => 'Compiles the server';

  late final flavor = argResults?['flavor'] as String?;

  @override
  Future<int> run() async {
    final root = await rootOf(rootPath);

    final generator = ConstructGenerator.release(
      flavor: flavor,
      routesHandler: routesHandler,
      constructs: constructs,
      logger: logger,
      fs: fs,
      rootPath: root.path,
    );

    final progress = logger.progress('Generating server code');

    await generator.generate();

    progress.complete('Generated server code');

    return 0;
  }
}
