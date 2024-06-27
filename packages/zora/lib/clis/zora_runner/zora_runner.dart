import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:zora/clis/zora_runner/commands/dev_command.dart';
import 'package:zora/handlers/construct_entrypoint_handler.dart';

class ZoraRunner extends CommandRunner<int> {
  ZoraRunner({
    required this.logger,
    required String initialDirectory,
    required FileSystem fs,
  }) : super('zora', 'Zora code generator') {
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

    addCommand(
      DevCommand(
        logger: logger,
        generator: ConstructEntrypointHandler(
          logger: logger,
          initialDirectory: initialDirectory,
          fs: fs,
        ),
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
  Future<int> runCommand(ArgResults args) async {
    final result = await super.runCommand(args);

    return result ?? 0;
  }
}
