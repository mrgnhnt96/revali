import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/models/meta_type.dart';
import 'package:revali_construct/utils/element_extensions.dart';

class MetaFromJson {
  const MetaFromJson({
    required this.params,
    required this.element,
  });

  final List<MetaType> params;
  final Element element;

  bool get isMethod => element is MethodElement;
  bool get isConstructor => element is ConstructorElement;

  static MetaFromJson? fromElement(Element? element) {
    if (element == null) {
      return null;
    }

    final fromJson = element.fromJsonElement;

    if (fromJson == null) {
      return null;
    }

    final params = switch (fromJson) {
      MethodElement(:final parameters) ||
      ConstructorElement(:final parameters) =>
        [
          for (final parameter in parameters) MetaType.fromType(parameter.type),
        ],
      _ => null,
    };

    if (params == null) {
      return null;
    }

    return MetaFromJson(
      params: params,
      element: fromJson,
    );
  }
}
