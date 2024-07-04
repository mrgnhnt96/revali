import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali/ast/checkers/type_checker.dart';

Iterable<DartObject> getAnnotations({
  required Type classType,
  required String package,
  required Element element,
}) {
  final checker = TypeChecker.fromName('$classType', packageName: package);

  final annotations = checker.annotationsOf(element);

  return annotations;
}
