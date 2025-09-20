import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_construct/models/meta_type.dart';
import 'package:revali_construct/utils/element_extensions.dart';

class MetaToJson {
  const MetaToJson({required this.returnType});

  static MetaToJson? fromElement(Element? element) {
    if (element == null) {
      return null;
    }

    if (element case MethodElement(name: 'toJson')) {
      return MetaToJson(returnType: MetaType.fromType(element.returnType));
    }

    return fromElement(element.toJsonElement);
  }

  final MetaType returnType;
}
