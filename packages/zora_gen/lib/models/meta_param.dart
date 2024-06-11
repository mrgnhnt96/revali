import 'package:analyzer/dart/element/element.dart';

class MetaParam {
  const MetaParam({
    required this.name,
    required this.type,
    required this.typeElement,
    required this.nullable,
    required this.isRequired,
    required this.annotations,
  });

  final String name;
  final String type;
  final Element typeElement;
  final bool nullable;
  final bool isRequired;
  final Iterable<ElementAnnotation> annotations;
}
