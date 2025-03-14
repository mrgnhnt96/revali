import 'package:analyzer/dart/element/type.dart';

enum IterableType {
  list,
  set,
  iterable;

  static IterableType? fromType(InterfaceType type) {
    if (type.isDartCoreList) {
      return IterableType.list;
    }

    if (type.isDartCoreSet) {
      return IterableType.set;
    }

    if (type.isDartCoreIterable) {
      return IterableType.iterable;
    }

    return null;
  }

  bool get isIterable => this == iterable;
  bool get isList => this == list;
  bool get isSet => this == set;
}
