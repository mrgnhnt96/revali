import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class DevCommand extends Command<int> {
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
            'Whether to run in release mode. Disabled hot reload and debugger',
        negatable: false,
      )
      ..addFlag(
        'debug',
        help: '(Default) Whether to run in debug mode. '
            'Enables hot reload and debugger',
        negatable: false,
      )
      ..addOption(
        'dart-vm-service-port',
        help: 'The port to use for the Dart VM service',
        defaultsTo: '8080',
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

  final ConstructEntrypointHandler _generator;
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

    await _generator.generate(recompile: recompile);
    logger.write('\n');

    await _generator.run(constructRunnerArgs);

    return 0;
  }

  List<String> get constructRunnerArgs {
    final argResults = this.argResults!;

    final argsToPass = <String>[];

    const ignore = {'--recompile'};

    for (final entry in ['dev', ...argResults.arguments]) {
      if (ignore.contains(entry)) {
        continue;
      }

      argsToPass.add(entry);
    }

    logger.detail('Construct Args: $argsToPass');

    return argsToPass;
  }
}
