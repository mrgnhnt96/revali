import 'package:path/path.dart' as p;
import 'package:revali/clis/revali_runner/commands/ai/ai_templates.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_tool_command.dart';

class AiCursorCommand extends AiToolCommand {
  AiCursorCommand({required super.fs, required super.logger});

  @override
  String get name => 'cursor';

  @override
  String get description =>
      'Install Cursor reference files (.cursor/rules/revali-*.mdc)';

  @override
  Map<String, String> files() => {
    for (final entry in cursorMdcFiles.entries)
      p.join('.cursor', 'rules', entry.key): entry.value,
  };
}
