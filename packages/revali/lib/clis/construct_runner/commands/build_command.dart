import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/construct_runner/commands/mixins/dart_defines_mixin.dart';
import 'package:revali/clis/construct_runner/generator/construct_generator.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/models/construct_maker.dart';

class BuildCommand extends Command<int>
    with DirectoriesMixin, DartDefinesMixin {
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
      ..addFlag(
        'release',
        help: '(Default) Whether to run in release mode. Disabled hot reload, '
            'debugger, and logger',
      )
      ..addFlag(
        'profile',
        help: 'Whether to run in profile mode. Enables logger, '
            'but disables hot reload and debugger',
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
  late final release = argResults?['release'] as bool? ?? true;
  late final profile = argResults?['profile'] as bool? ?? false;

  @override
  Future<int> run() async {
    final root = await rootOf(rootPath);

    final generator = switch ((profile, release)) {
      (true, _) => ConstructGenerator.profile,
      _ => ConstructGenerator.release,
    }(
      flavor: flavor,
      routesHandler: routesHandler,
      makers: constructs,
      logger: logger,
      fs: fs,
      rootPath: root.path,
      dartDefines: defines,
      generateBuild: true,
    );

    await generator.clean();

    final progress = logger.progress('Generating server code');

    final success = await generator.generate();

    if (!success) {
      progress.fail('Failed to generate server code');
      return 1;
    }

    progress.complete('Generated server code');

    return 0;
  }
}
