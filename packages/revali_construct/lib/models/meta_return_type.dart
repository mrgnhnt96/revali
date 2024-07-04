import 'package:analyzer/dart/element/element.dart';

class MetaReturnType {
  MetaReturnType({
    required this.isVoid,
    required this.isNullable,
    required this.type,
    required this.isFuture,
    this.element,
  });

  final bool isVoid;
  final bool isNullable;
  final String type;
  final Element? element;
  final bool isFuture;

  bool get isPrimitive {
    return type == 'String' ||
        type == 'int' ||
        type == 'double' ||
        type == 'num' ||
        type == 'bool';
  }
}
