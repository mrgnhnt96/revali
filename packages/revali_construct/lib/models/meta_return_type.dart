import 'package:analyzer/dart/element/element.dart';

class MetaReturnType {
  MetaReturnType({
    required this.isVoid,
    required this.isNullable,
    required this.type,
    this.element,
  });

  final bool isVoid;
  final bool isNullable;
  final String type;
  final Element? element;

  bool get isPrimitive {
    return type == 'String' ||
        type == 'int' ||
        type == 'double' ||
        type == 'num' ||
        type == 'bool';
  }
}
