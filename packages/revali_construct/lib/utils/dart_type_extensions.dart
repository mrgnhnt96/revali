import 'package:analyzer/dart/element/type.dart';

extension DartTypeX on DartType {
  bool get isPrimitive {
    bool isPrimitive(DartType type) {
      return switch (type) {
        DartType(isDartCoreBool: true) => true,
        DartType(isDartCoreInt: true) => true,
        DartType(isDartCoreDouble: true) => true,
        DartType(isDartCoreString: true) => true,
        DartType(isDartCoreNum: true) => true,
        _ => false,
      };
    }

    if (isFuture || isStream) {
      if (element case InterfaceType(:final typeArguments)) {
        if (typeArguments.length != 1) {
          return false;
        }

        return isPrimitive(typeArguments.first);
      }

      return false;
    }

    if (isVoid) {
      return false;
    }

    return isPrimitive(this);
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
