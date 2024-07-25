import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class DevCommand extends Command<int> {
  DevCommand({
    required ConstructEntrypointHandler generator,
    required this.logger,
  }) : _generator = generator {
    argParser
      ..addFlag(
        'recompile',
        help: 'Re-compiles the construct kernel. '
            'Needed to sync changes for a local construct.',
        negatable: false,
      )
      ..addOption(
        'flavor',
        abbr: 'f',
        help: 'The flavor to use for the app (case-sensitive)',
      )
      ..addFlag(
        'release',
        help:
            'Whether to run in release mode. Disabled hot reload and debugger',
        negatable: false,
      )
      ..addFlag(
        'debug',
        help: '(Default) Whether to run in debug mode. '
            'Enables hot reload and debugger',
        negatable: false,
      );
  }

  final ConstructEntrypointHandler _generator;
  final Logger logger;

  @override
  String get name => 'dev';

  @override
  String get description => 'Starts the development server';

  @override
  Future<int> run() async {
    final argResults = this.argResults!;
    final recompile = argResults['recompile'] as bool;

    await _generator.generate(recompile: recompile);
    logger.write('\n');

    await _generator.run(constructRunnerArgs);

    return 0;
  }

  List<String> get constructRunnerArgs {
    final argResults = this.argResults!;

    final argsToPass = ['dev', ...argResults.arguments]..remove('--recompile');

    logger.detail('Construct Args: $argsToPass');

    return argsToPass;
  }
}
