import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/construct_runner/commands/mixins/dart_defines_mixin.dart';
import 'package:revali/clis/construct_runner/generator/construct_generator.dart';
import 'package:revali/handlers/routes_handler.dart';
import 'package:revali/utils/mixins/directories_mixin.dart';
import 'package:revali_construct/revali_construct.dart';

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
        negatable: false,
      )
      ..addFlag(
        'profile',
        help: 'Whether to run in profile mode. Enables logger, '
            'but disables hot reload and debugger',
        negatable: false,
      )
      ..addOption(
        'type',
        allowedHelp: {
          for (final type in GenerateConstructType.values)
            type.name: type.description,
        },
        hide: true,
        allowed: GenerateConstructType.values.map((e) => e.name),
        defaultsTo: GenerateConstructType.build.name,
        help: 'Which constructs to generate',
      )
      ..addMultiOption(
        'dart-define',
        abbr: 'D',
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
  late final type =
      GenerateConstructType.values.byName(argResults?['type'] as String);

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
      generateConstructType: type,
    );

    await generator.clean(type: type);

    final progress = logger.progress('Building');

    if (await generator.generate(progress.update) case final server
        when server == null) {
      progress.fail('Build failed');
      logger.flush();
      return 1;
    }

    progress.complete('Build succeeded');

    return 0;
  }
}
