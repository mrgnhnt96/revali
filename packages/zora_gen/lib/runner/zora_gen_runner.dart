import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:zora_gen/generators/entrypoint.dart';
import 'package:zora_gen/runner/commands/dev_command.dart';

class ZoraGenRunner extends CommandRunner<int> {
  ZoraGenRunner({
    required String initialDirectory,
    required FileSystem fs,
  }) : super('zora_gen', 'Zora code generator') {
    addCommand(
      DevCommand(
        generator: EntrypointGenerator(
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
