import 'package:revali/clis/revali_runner/commands/ai/ai_templates.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_tool_command.dart';

class AiWindsurfCommand extends AiToolCommand {
  AiWindsurfCommand({required super.fs, required super.logger});

  @override
  String get name => 'windsurf';

  @override
  String get description =>
      'Install the Windsurf reference file (.windsurfrules)';

  @override
  Map<String, String> files() => {'.windsurfrules': windsurfRules};
}
