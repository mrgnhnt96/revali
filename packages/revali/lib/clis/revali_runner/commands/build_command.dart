import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/mixins/construct_runner_args.dart';
import 'package:revali/clis/shared/commands/construct_flags.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class BuildCommand extends Command<int> with ConstructRunnerArgs {
  BuildCommand({
    required ConstructEntrypointHandler generator,
    required this.logger,
    required this.fs,
  }) : _generator = generator {
    sharedBuildFlags.declareAll(argParser);

    argParser.addFlag(
      'recompile',
      help:
          'Re-compiles the construct kernel. '
          'Needed to sync changes for a local construct.',
      negatable: false,
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

  @override
  List<ConstructFlag> get forwardedFlags => sharedBuildFlags;

  late final recompile = argResults?['recompile'] as bool;

  @override
  Future<int> run() async {
    try {
      final shouldRun = await _generator.generate(recompile: recompile);
      if (!shouldRun) {
        return 0;
      }
    } catch (e) {
      logger.err('Failed to generate the construct');
      return 1;
    }

    logger.write('\n');

    return _generator.run(constructRunnerArgs);
  }
}
