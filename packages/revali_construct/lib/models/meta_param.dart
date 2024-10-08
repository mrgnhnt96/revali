import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/types/annotation_getter.dart';

class MetaParam {
  const MetaParam({
    required this.name,
    required this.type,
    required this.typeImport,
    required this.typeElement,
    required this.nullable,
    required this.isRequired,
    required this.isNamed,
    required this.defaultValue,
    required this.annotationsFor,
  });

  final String name;
  final String type;
  final String? typeImport;
  final Element typeElement;
  final bool nullable;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final AnnotationMapper annotationsFor;

  bool get hasDefaultValue => defaultValue != null;
}
