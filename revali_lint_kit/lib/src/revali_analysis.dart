import 'package:lint_kit/lint_kit.dart';

class RevaliAnalysis implements LintKitAnalyzer {
  const RevaliAnalysis();

  @override
  String get packageName => 'revali_lint_kit';

  @override
  List<LintKitAnalyzer> get plugins => [];

  Iterable<Message> lints(AnalyzedFile file) sync* {
    final lines = file.content.split('\n');

    for (final (index, line) in lines.indexed) {
      if (!line.contains('const')) {
        continue;
      }

      final constIndex = line.indexOf('const');

      yield Lint(
        range: Range(
          start: Position(line: index, character: constIndex),
          end: Position(line: index, character: constIndex + 'const'.length),
        ),
        code: 'example_lint',
        message: 'Hey, Listen! 🧚',
        path: file.path,
      );
    }
  }

  @override
  Future<List<Message>> analyze(
    AnalyzedFile file,
    AnalysisOptions? options,
  ) async {
    return lints(file).toList();
  }
}
