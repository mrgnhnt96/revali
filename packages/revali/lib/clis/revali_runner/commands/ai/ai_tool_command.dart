import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_writer.dart';

/// Base for every `revali ai <tool>` subcommand — writes [files] (a map of
/// project-relative path to file contents), skipping any that already exist
/// unless `--force` is passed.
abstract class AiToolCommand extends Command<int> {
  AiToolCommand({required this.fs, required this.logger}) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing files',
      negatable: false,
    );
  }

  final FileSystem fs;
  final Logger logger;

  bool get force => argResults?['force'] as bool? ?? false;

  Map<String, String> files();

  @override
  FutureOr<int>? run() {
    for (final entry in files().entries) {
      writeAiFile(
        fs: fs,
        logger: logger,
        path: entry.key,
        contents: entry.value,
        force: force,
      );
    }

    return 0;
  }
}
