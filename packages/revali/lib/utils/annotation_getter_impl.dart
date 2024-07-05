import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali/ast/checkers/type_checker.dart';
import 'package:revali/revali.dart';
import 'package:revali_construct/types/annotation_getter.dart';

void getAnnotations({
  required Element element,
  required List<OnClass> on,
}) {
  for (var i = 0; i < element.metadata.length; i++) {
    final value = _computeConstantValue(
      element,
      i,
    );

    if (value?.type case final type?) {
      for (final onClass in on) {
        if (onClass.predicate(type)) {
          var source = element.metadata[i].toSource();
          if (source.contains('@')) {
            source = source.substring(source.indexOf('@') + 1);
          }

          onClass.convert(value, source);
          break;
        }
      }
    }
  }
}

DartObject? _computeConstantValue(Element element, int annotationIndex) {
  final annotation = element.metadata[annotationIndex];
  final result = annotation.computeConstantValue();

  return result;
}

extension _OnClassX on OnClass {
  TypeChecker get checker => TypeChecker.fromName(
        '$classType',
        ignoreGenerics: true,
        packageName: package,
      );

  bool predicate(DartType type) {
    return checker.isExactlyType(type);
  }
}
