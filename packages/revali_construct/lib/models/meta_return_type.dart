import 'package:analyzer/dart/element/element.dart';

class MetaReturnType {
  MetaReturnType({
    required this.isVoid,
    required this.isNullable,
    required this.type,
    required this.isFuture,
    required this.isStream,
    required this.typeArguments,
    this.element,
  });

  final bool isVoid;
  final bool isNullable;
  final String type;
  final List<String> typeArguments;
  final Element? element;
  final bool isFuture;
  final bool isStream;
  bool get isMap {
    if (type.startsWith('Map')) {
      return true;
    }

    if (typeArguments.length != 1) {
      return false;
    }

    return typeArguments.first.startsWith('Map');
  }

  bool get isPrimitive {
    bool isPrimitive(String value) {
      return value == 'String' ||
          value == 'int' ||
          value == 'double' ||
          value == 'num' ||
          value == 'bool';
    }

    if (isFuture || isStream) {
      if (typeArguments.length != 1) {
        return false;
      }

      return isPrimitive(typeArguments.first);
    }

    if (isVoid) {
      return false;
    }

    return isPrimitive(type);
  }
}
