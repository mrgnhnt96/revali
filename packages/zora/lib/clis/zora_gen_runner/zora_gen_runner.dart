import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:zora/clis/zora_gen_runner/commands/dev_command.dart';
import 'package:zora/handlers/construct_entrypoint_handler.dart';

class ZoraGenRunner extends CommandRunner<int> {
  ZoraGenRunner({
    required String initialDirectory,
    required FileSystem fs,
  }) : super('zora', 'Zora code generator') {
    addCommand(
      DevCommand(
        generator: ConstructEntrypointHandler(
          initialDirectory: initialDirectory,
          fs: fs,
        ),
      ),
    );
  }

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
