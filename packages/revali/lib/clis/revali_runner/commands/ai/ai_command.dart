import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/all_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/claude_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/cline_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/copilot_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/cursor_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/windsurf_command.dart';

class AiCommand extends Command<int> {
  AiCommand({required FileSystem fs, required Logger logger}) {
    addSubcommand(AiClaudeCommand(fs: fs, logger: logger));
    addSubcommand(AiCursorCommand(fs: fs, logger: logger));
    addSubcommand(AiCopilotCommand(fs: fs, logger: logger));
    addSubcommand(AiWindsurfCommand(fs: fs, logger: logger));
    addSubcommand(AiClineCommand(fs: fs, logger: logger));
    addSubcommand(AiAllCommand(fs: fs, logger: logger));
  }

  @override
  String get name => 'ai';

  @override
  String get description =>
      'Install AI coding assistant reference files into your project';
}
