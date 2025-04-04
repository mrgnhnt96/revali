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

    if (element is ClassElement) {
      for (final method in element.methods) {
        if (method.name != 'toJson') {
          continue;
        }

        return fromElement(method);
      }
    }

    return null;
  }

  final MetaType returnType;
}
