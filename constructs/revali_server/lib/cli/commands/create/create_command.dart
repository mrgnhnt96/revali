import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:change_case/change_case.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_app_command.dart';
import 'package:revali_server/cli/commands/create/create_components/create_controller_command.dart';
import 'package:revali_server/cli/commands/create/create_components/create_lifecycle_component_command.dart';
import 'package:revali_server/cli/commands/create/create_components/create_observer_command.dart';
import 'package:revali_server/cli/commands/create/create_components/create_pipe_command.dart';

class CreateCommand extends Command<int> {
  CreateCommand({required FileSystem fs, required this.logger}) {
    final subCommands = [
      CreateAppCommand.new,
      CreateControllerCommand.new,
      CreateLifecycleComponentCommand.new,
      CreateObserverCommand.new,
      CreatePipeCommand.new,
    ];

    for (final sub in subCommands) {
      addSubcommand(sub(fs: fs, logger: logger));
    }
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create components for Revali Server';

  final Logger logger;

  @override
  // ignore: unnecessary_overrides
  FutureOr<int>? run() async {
    final commands = {
      for (final key in subcommands.keys) key.toNoCase().toTitleCase(): key,
    };

    final choice = logger.chooseOne(
      'What would you like to create?',
      choices: commands.keys.toList(),
    );

    final key = commands[choice];

    final command = subcommands[key];

    if (command == null) {
      logger.err('Failed to find command');
      return -1;
    }

    final result = await command.run();

    return result ?? 0;
  }
}
