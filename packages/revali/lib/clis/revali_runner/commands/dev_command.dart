import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/mixins/construct_runner_args.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class DevCommand extends Command<int> with ConstructRunnerArgs {
  DevCommand({
    required ConstructEntrypointHandler generator,
    required this.logger,
    required this.fs,
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
            'Whether to run in release mode. Disables hot reload and debugger',
        negatable: false,
      )
      ..addFlag(
        'debug',
        help: '(Default) Whether to run in debug mode. '
            'Enables hot reload and debugger',
        negatable: false,
      )
      ..addFlag(
        'generate-only',
        help: 'Only generate the constructs, does not run the server',
        negatable: false,
        hide: true,
      )
      ..addOption(
        'dart-vm-service-port',
        help: 'The port to use for the Dart VM service',
        defaultsTo: '8079',
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

  final ConstructEntrypointHandler _generator;
  @override
  final Logger logger;
  final FileSystem fs;

  @override
  String get name => 'dev';

  @override
  String get description => 'Starts the development server';

  @override
  Future<int> run() async {
    final argResults = this.argResults!;
    final recompile = argResults['recompile'] as bool;

    try {
      await _generator.generate(recompile: recompile);
    } catch (e) {
      logger
        ..detail('Error: $e')
        ..err('Failed to generate the construct');
      return 1;
    }
    logger.write('\n');

    await _generator.run(constructRunnerArgs);

    return 0;
  }
}
