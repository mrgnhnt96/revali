import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/types/annotation_getter.dart';
import 'package:revali_construct/utils/type_checker.dart';

void getAnnotations({
  required Element element,
  required List<OnMatch> onMatch,
  NonMatch? onNonMatch,
}) {
  for (var i = 0; i < element.metadata.annotations.length; i++) {
    final value = _computeConstantValue(element, i);

    if (value == null) {
      continue;
    }

    if (value.type case final type?) {
      var found = false;
      for (final onClass in onMatch) {
        if (onClass.predicate(type)) {
          final annotation = element.metadata.annotations[i];

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

      onNonMatch.convert(value, element.metadata.annotations[i]);
    }
  }
}

DartObject? _computeConstantValue(Element element, int annotationIndex) {
  final annotation = element.metadata.annotations[annotationIndex];
  final result = annotation.computeConstantValue();

  return result;
}

extension _MatcherX on Matcher {
  TypeChecker get checker => TypeChecker.fromName(
    classType,
    ignoreGenerics: ignoreGenerics,
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
