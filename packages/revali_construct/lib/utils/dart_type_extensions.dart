import 'package:analyzer/dart/element/type.dart';

extension DartTypeX on DartType {
  bool get isPrimitive {
    bool isPrimitive(String value) {
      return value == 'String' ||
          value == 'int' ||
          value == 'double' ||
          value == 'num' ||
          value == 'bool';
    }

    if (isFuture || isStream) {
      if (element case InterfaceType(:final typeArguments)) {
        if (typeArguments.length != 1) {
          return false;
        }

        return isPrimitive(typeArguments.first.getDisplayString());
      }

      return false;
    }

    if (isVoid) {
      return false;
    }

    return isPrimitive(getDisplayString());
  }

  bool get isVoid {
    return this is VoidType;
  }

  bool get isFuture {
    return isDartAsyncFuture || isDartAsyncFutureOr;
  }

  bool get isStream {
    return isDartAsyncStream;
  }
}
