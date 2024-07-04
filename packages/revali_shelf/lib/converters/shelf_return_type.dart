import 'package:revali_construct/revali_construct.dart';

class ShelfReturnType {
  const ShelfReturnType({
    required this.isVoid,
    required this.isFuture,
    required this.type,
    required this.isNullable,
    required this.isPrimitive,
  });

  factory ShelfReturnType.fromMeta(MetaReturnType type) {
    return ShelfReturnType(
      isVoid: type.isVoid,
      isFuture: type.isFuture,
      type: type.type,
      isNullable: type.isNullable,
      isPrimitive: type.isPrimitive,
    );
  }

  final bool isVoid;
  final bool isFuture;
  final String type;
  final bool isNullable;
  final bool isPrimitive;
}
