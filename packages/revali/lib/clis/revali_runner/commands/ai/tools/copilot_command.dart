import 'package:path/path.dart' as p;
import 'package:revali/clis/revali_runner/commands/ai/ai_templates.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_tool_command.dart';

class AiCopilotCommand extends AiToolCommand {
  AiCopilotCommand({required super.fs, required super.logger});

  @override
  String get name => 'copilot';

  @override
  String get description =>
      'Install the GitHub Copilot reference file (.github/copilot-instructions.md)';

  @override
  Map<String, String> files() => {
    p.join('.github', 'copilot-instructions.md'): copilotMd,
  };
}
