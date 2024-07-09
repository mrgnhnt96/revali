import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_reflect.dart';

class ShelfReturnType {
  const ShelfReturnType({
    required this.isVoid,
    required this.isFuture,
    required this.type,
    required this.isNullable,
    required this.isPrimitive,
    required this.reflect,
  });

  factory ShelfReturnType.fromMeta(MetaReturnType type) {
    ShelfReflect? reflect;
    if (type.element case final element?) {
      reflect = ShelfReflect.fromElement(element);
    }

    return ShelfReturnType(
      isVoid: type.isVoid,
      isFuture: type.isFuture,
      type: type.type,
      isNullable: type.isNullable,
      isPrimitive: type.isPrimitive,
      reflect: reflect,
    );
  }

  final bool isVoid;
  final bool isFuture;
  final String type;
  final bool isNullable;
  final bool isPrimitive;
  final ShelfReflect? reflect;
}
