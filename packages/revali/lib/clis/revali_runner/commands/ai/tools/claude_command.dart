import 'package:revali/clis/revali_runner/commands/ai/ai_templates.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_tool_command.dart';

class AiClaudeCommand extends AiToolCommand {
  AiClaudeCommand({required super.fs, required super.logger});

  @override
  String get name => 'claude';

  @override
  String get description =>
      'Install the Claude Code reference file (CLAUDE.md)';

  @override
  Map<String, String> files() => {'CLAUDE.md': claudeMd};
}
