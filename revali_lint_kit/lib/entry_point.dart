import 'package:revali_lint_kit/src/revali_analysis.dart';
import 'package:lint_kit/lint_kit.dart';

LintKitAnalyzer entrypoint() {
  return const RevaliAnalysis();
}
