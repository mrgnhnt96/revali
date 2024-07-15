import 'package:analyzer/dart/element/element.dart';
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
    required this.hasToJsonMember,
  });

  factory ServerReturnType.fromMeta(MetaReturnType type) {
    ServerReflect? reflect;
    var hasToJsonMember = false;

    if (type.element case final element?) {
      reflect = ServerReflect.fromElement(element);
      if (element is ClassElement) {
        hasToJsonMember = element.methods.any((e) => e.name == 'toJson');
      }
    }

    return ServerReturnType(
      isVoid: type.isVoid,
      isFuture: type.isFuture,
      type: type.type,
      isNullable: type.isNullable,
      isPrimitive: type.isPrimitive,
      reflect: reflect,
      hasToJsonMember: hasToJsonMember,
    );
  }

  final bool isVoid;
  final bool isFuture;
  final String type;
  final bool isNullable;
  final bool isPrimitive;
  final ServerReflect? reflect;
  final bool hasToJsonMember;
}
