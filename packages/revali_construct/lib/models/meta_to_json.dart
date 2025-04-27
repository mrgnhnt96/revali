import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/models/meta_type.dart';

class MetaToJson {
  const MetaToJson({
    required this.returnType,
  });

  static MetaToJson? fromElement(Element? element) {
    if (element == null) {
      return null;
    }

    if (element is MethodElement) {
      return MetaToJson(returnType: MetaType.fromType(element.returnType));
    }

    final methods = switch (element) {
      ClassElement(:final methods) => methods,
      EnumElement(:final methods) => methods,
      _ => <MethodElement>[],
    };

    for (final method in methods) {
      if (method.name != 'toJson') {
        continue;
      }

      return fromElement(method);
    }

    return null;
  }

  final MetaType returnType;
}
