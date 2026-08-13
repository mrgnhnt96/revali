import 'package:file/file.dart';
import 'package:revali/ast/analyzer/analyzer.dart';
import 'package:revali/clis/construct_runner/commands/build_command.dart';
import 'package:revali/clis/construct_runner/commands/dev_command.dart';
import 'package:revali/clis/shared/commands/revali_command_runner.dart';
import 'package:revali_construct/revali_construct.dart';

class ConstructRunner extends RevaliCommandRunner {
  ConstructRunner({
    required this.constructs,
    required this.rootPath,
    required super.logger,
    required FileSystem fs,
    required Analyzer analyzer,
  }) : super('', 'Generates the construct') {
    addCommand(
      DevCommand(
        fs: fs,
        rootPath: rootPath,
        constructs: constructs,
        logger: logger,
        analyzer: analyzer,
      ),
    );
    addCommand(
      BuildCommand(
        fs: fs,
        rootPath: rootPath,
        constructs: constructs,
        logger: logger,
        analyzer: analyzer,
      ),
    );
  }

  final List<ConstructMaker> constructs;
  final String rootPath;
}
