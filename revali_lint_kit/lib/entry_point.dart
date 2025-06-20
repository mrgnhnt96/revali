import 'package:lint_kit/lint_kit.dart';
import 'package:revali_lint_kit/src/revali_analysis.dart';

LintKitAnalyzer entrypoint() {
  return const RevaliAnalysis();
}
