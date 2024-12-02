import 'package:args/command_runner.dart';
import 'package:args/src/arg_results.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_command.dart';

class RevaliServerRunner extends CommandRunner<int> {
  RevaliServerRunner({
    required FileSystem fs,
    required Logger logger,
  }) : super('revali_server', 'CLI for revali_server') {
    addCommand(
      CreateCommand(
        fs: fs,
        logger: logger,
      ),
    );
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    final command = topLevelResults.command;

    if (command case final cmd?) {
      final command = switch (commands[cmd.name]) {
        final CreateCommand command => command,
        _ => null,
      };

      if (command != null) {
        return command.run(topLevelResults.arguments);
      }
    }

    return super.runCommand(topLevelResults);
  }
}
