import 'package:revali/clis/revali_runner/commands/ai/ai_tool_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/claude_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/cline_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/copilot_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/cursor_command.dart';
import 'package:revali/clis/revali_runner/commands/ai/tools/windsurf_command.dart';

class AiAllCommand extends AiToolCommand {
  AiAllCommand({required super.fs, required super.logger});

  @override
  String get name => 'all';

  @override
  String get description => 'Install reference files for every supported tool';

  @override
  Map<String, String> files() => {
    ...AiClaudeCommand(fs: fs, logger: logger).files(),
    ...AiCursorCommand(fs: fs, logger: logger).files(),
    ...AiCopilotCommand(fs: fs, logger: logger).files(),
    ...AiWindsurfCommand(fs: fs, logger: logger).files(),
    ...AiClineCommand(fs: fs, logger: logger).files(),
  };
}
