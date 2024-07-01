import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

class MetaParam {
  const MetaParam({
    required this.name,
    required this.type,
    required this.typeElement,
    required this.nullable,
    required this.isRequired,
    required this.isNamed,
    required this.annotations,
    required this.defaultValue,
    required this.annotationFor,
  });

  final String name;
  final String type;
  final Element typeElement;
  final bool nullable;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final DartObject? Function(
      {required String className, required String package}) annotationFor;
  final Iterable<ElementAnnotation> annotations;

  bool get hasDefaultValue => defaultValue != null;
}
