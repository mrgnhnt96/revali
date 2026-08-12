import 'package:revali/clis/revali_runner/commands/ai/ai_templates.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_tool_command.dart';

class AiClineCommand extends AiToolCommand {
  AiClineCommand({required super.fs, required super.logger});

  @override
  String get name => 'cline';

  @override
  String get description => 'Install the Cline reference file (.clinerules)';

  @override
  Map<String, String> files() => {'.clinerules': clineRules};
}
