import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali_server/cli/commands/create/create_components/create_app_command.dart';
import 'package:revali_server/cli/commands/create/create_components/create_controller_command.dart';

class CreateCommand extends Command<int> {
  CreateCommand({
    required FileSystem fs,
    required this.logger,
  }) {
    addSubcommand(
      CreateControllerCommand(
        fs: fs,
        logger: logger,
      ),
    );
    addSubcommand(
      CreateAppCommand(
        fs: fs,
        logger: logger,
      ),
    );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create components for Revali Server';

  final Logger logger;

  @override
  ArgResults? argResults;

  bool get help => argResults?['help'] as bool;

  @override
  // ignore: unnecessary_overrides
  FutureOr<int>? run([List<String> args = const []]) async {
    argResults ??= argParser.parse(args);
    if (help) {
      printUsage();
      return 0;
    }

    final commands = subcommands.keys.toList();

    final choice = logger.chooseOne(
      'What would you like to create?',
      choices: commands,
    );

    final result = await subcommands[choice]?.run();

    return result ?? 0;
  }
}
