import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';

class Units {
  Units({required AnalysisContext context, required String path})
    : _resolved = context.currentSession.getResolvedUnit(path),
      _parsed = context.currentSession.getParsedUnit(path);

  final Future<SomeResolvedUnitResult> _resolved;
  final SomeParsedUnitResult _parsed;

  ParsedUnitResult get parsed {
    if (_parsed case final ParsedUnitResult parsed) {
      return parsed;
    }

    throw UnimplementedError('No parsed unit found');
  }

  ResolvedUnitResult? __resolved;
  Future<ResolvedUnitResult> resolved() async {
    if (__resolved case final ResolvedUnitResult resolved) {
      return resolved;
    }

    final result = await _resolved;

    if (result is! ResolvedUnitResult) {
      throw ArgumentError('Could not resolve unit: $result');
    }

    return __resolved = result;
  }
}
