import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali/ast/checkers/type_checker.dart';
import 'package:revali/revali.dart';
import 'package:revali_construct/types/annotation_getter.dart';

void getAnnotations({
  required Element element,
  required List<OnMatch> onMatch,
  required NonMatch? onNonMatch,
}) {
  for (var i = 0; i < element.metadata.length; i++) {
    final value = _computeConstantValue(
      element,
      i,
    );

    if (value == null) {
      continue;
    }

    if (value.type case final type?) {
      var found = false;
      for (final onClass in onMatch) {
        if (onClass.predicate(type)) {
          final annotation = element.metadata[i];

          onClass.convert(value, annotation);
          found = true;
          break;
        }
      }

      if (found) {
        continue;
      }

      if (onNonMatch == null) {
        continue;
      }

      if (onNonMatch.ignore.any((ignore) => ignore.predicate(type))) {
        continue;
      }

      onNonMatch.convert(value, element.metadata[i]);
    }
  }
}

DartObject? _computeConstantValue(Element element, int annotationIndex) {
  final annotation = element.metadata[annotationIndex];
  final result = annotation.computeConstantValue();

  return result;
}

extension _MatcherX on Matcher {
  TypeChecker get checker => TypeChecker.fromName(
        classType,
        ignoreGenerics: true,
        packageName: package,
      );

  bool predicate(DartType type) {
    if (checker.isExactlyType(type)) {
      return true;
    }

    if (checker.isAssignableFromType(type)) {
      return true;
    }

    return false;
  }
}
