import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:zora/handlers/construct_entrypoint_handler.dart';

class DevCommand extends Command<int> {
  DevCommand({
    required ConstructEntrypointHandler generator,
    required this.logger,
  }) : _generator = generator {
    argParser
      ..addFlag(
        'recompile',
        help:
            'Re-compiles the construct kernel. Needed to sync changes for a local construct.',
        negatable: false,
        defaultsTo: false,
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
    final recompile = argResults!['recompile'] as bool;

    await _generator.generate(recompile: recompile);
    logger.write('\n');
    await _generator.run(['dev']);

    return 0;
  }
}
