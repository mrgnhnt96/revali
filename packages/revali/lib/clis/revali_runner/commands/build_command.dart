import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/mixins/construct_runner_args.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';
import 'package:revali_construct/revali_construct.dart';

class BuildCommand extends Command<int> with ConstructRunnerArgs {
  BuildCommand({
    required ConstructEntrypointHandler generator,
    required this.logger,
    required this.fs,
  }) : _generator = generator {
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
      ..addFlag(
        'recompile',
        help: 'Re-compiles the construct kernel. '
            'Needed to sync changes for a local construct.',
        negatable: false,
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

  @override
  final Logger logger;
  final FileSystem fs;
  final ConstructEntrypointHandler _generator;

  @override
  String get name => 'build';

  @override
  String get description => 'Compiles the server';

  late final recompile = argResults?['recompile'] as bool;

  @override
  Future<int> run() async {
    try {
      await _generator.generate(recompile: recompile);
    } catch (e) {
      logger.err('Failed to generate the construct');
      return 1;
    }

    logger.write('\n');

    await _generator.run(constructRunnerArgs);

    return 0;
  }
}
