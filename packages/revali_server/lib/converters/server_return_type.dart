import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_reflect.dart';

class ServerReturnType {
  const ServerReturnType({
    required this.isVoid,
    required this.isFuture,
    required this.type,
    required this.isNullable,
    required this.isPrimitive,
    required this.reflect,
  });

  factory ServerReturnType.fromMeta(MetaReturnType type) {
    ServerReflect? reflect;
    if (type.element case final element?) {
      reflect = ServerReflect.fromElement(element);
    }

    return ServerReturnType(
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
  final ServerReflect? reflect;
}
