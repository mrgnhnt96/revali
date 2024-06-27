import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:zora/construct_runner/commands/dev_command.dart';
import 'package:zora_construct/zora_construct.dart';

class ConstructRunner extends CommandRunner<int> {
  ConstructRunner({
    required this.constructs,
    required this.rootPath,
    required FileSystem fs,
  }) : super('', 'Generates the construct') {
    addCommand(DevCommand(
      fs: fs,
      rootPath: rootPath,
      constructs: constructs,
    ));
  }

  final List<ConstructMaker> constructs;
  final String rootPath;

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
