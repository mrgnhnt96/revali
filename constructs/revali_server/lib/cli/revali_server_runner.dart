import 'package:args/command_runner.dart';
// ignore: implementation_imports
import 'package:args/src/arg_results.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_command.dart';

class RevaliServerRunner extends CommandRunner<int> {
  RevaliServerRunner({required FileSystem fs, required this.logger})
    : super('revali_server', 'CLI for revali_server') {
    addCommand(CreateCommand(fs: fs, logger: logger));
  }

  final Logger logger;

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    final command = topLevelResults.command;

    try {
      if (command case final cmd? when cmd.arguments.isEmpty) {
        final command = switch (commands[cmd.name]) {
          final CreateCommand command => command,
          _ => null,
        };

        if (command != null) {
          logger.detail('Running command: ${command.name}');
          return await command.run();
        }
      }

      return super.runCommand(topLevelResults);
    } catch (e) {
      logger
        ..err('An error occurred')
        ..detail('$e');
    }
    return null;
  }
}
