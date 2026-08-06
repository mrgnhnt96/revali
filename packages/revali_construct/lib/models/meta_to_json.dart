import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/models/meta_type.dart';
import 'package:revali_construct/utils/element_extensions.dart';

class MetaToJson {
  const MetaToJson({required this.returnType, required this.paramCount});

  static MetaToJson? fromElement(Element? element) {
    if (element == null) {
      return null;
    }

    if (element case MethodElement(name: 'toJson', :final formalParameters)) {
      return MetaToJson(
        returnType: MetaType.fromType(element.returnType),
        paramCount: formalParameters.length,
      );
    }

    return fromElement(element.toJsonElement);
  }

  final MetaType returnType;

  /// Number of `Object Function(T)` closures the method expects, one per
  /// class type parameter. `0` for the plain, non-generic `toJson()` shape.
  final int paramCount;
}
