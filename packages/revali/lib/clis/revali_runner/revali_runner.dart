import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/build_command.dart';
import 'package:revali/clis/revali_runner/commands/dev_command.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';

class RevaliRunner extends CommandRunner<int> {
  RevaliRunner({
    required this.logger,
    required String initialDirectory,
    required FileSystem fs,
  }) : super('revali', 'revali code generator') {
    argParser
      ..addFlag(
        'loud',
        help: 'Prints detailed output',
        hide: true,
      )
      ..addFlag(
        'quiet',
        help: 'Limits output to important information only',
        hide: true,
      );

    final entrypointHandler = ConstructEntrypointHandler(
      logger: logger,
      initialDirectory: initialDirectory,
      fs: fs,
    );

    addCommand(
      DevCommand(
        fs: fs,
        logger: logger,
        generator: entrypointHandler,
      ),
    );
    addCommand(
      BuildCommand(
        fs: fs,
        logger: logger,
        generator: entrypointHandler,
      ),
    );
  }

  final Logger logger;

  @override
  Future<int> run(Iterable<String> args) async {
    final result = await super.run(args);

    return result ?? 0;
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    final result = await super.runCommand(topLevelResults);

    return result ?? 0;
  }
}
