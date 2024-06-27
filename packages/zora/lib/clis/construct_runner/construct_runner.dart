import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:zora/clis/construct_runner/commands/dev_command.dart';
import 'package:zora_construct/zora_construct.dart';

class ConstructRunner extends CommandRunner<int> {
  ConstructRunner({
    required this.constructs,
    required this.rootPath,
    required this.logger,
    required FileSystem fs,
  }) : super('', 'Generates the construct') {
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

    addCommand(DevCommand(
      fs: fs,
      rootPath: rootPath,
      constructs: constructs,
      logger: logger,
    ));
  }

  final List<ConstructMaker> constructs;
  final String rootPath;
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
