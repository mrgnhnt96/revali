import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_reflect.dart';

class ServerReturnType {
  const ServerReturnType({
    required this.isVoid,
    required this.isFuture,
    required this.isStream,
    required this.type,
    required this.isNullable,
    required this.isPrimitive,
    required this.reflect,
    required this.hasToJsonMember,
    required this.isStringContent,
  });

  factory ServerReturnType.fromMeta(MetaReturnType type) {
    ServerReflect? reflect;
    var hasToJsonMember = false;
    var isStringContent = false;

    if (type.element case final element?) {
      reflect = ServerReflect.fromElement(element);
      if (element is ClassElement) {
        hasToJsonMember = element.methods.any((e) => e.name == 'toJson');
        isStringContent = element.name == '$StringContent' ||
            element.allSupertypes.any(
              (e) =>
                  e.getDisplayString(withNullability: false) ==
                  '$StringContent',
            );
      }
    }

    return ServerReturnType(
      isVoid: type.isVoid,
      isFuture: type.isFuture,
      isStream: type.isStream,
      type: type.type,
      isNullable: type.isNullable,
      isPrimitive: type.isPrimitive,
      reflect: reflect,
      hasToJsonMember: hasToJsonMember,
      isStringContent: isStringContent,
    );
  }

  final bool isVoid;
  final bool isFuture;
  final bool isStream;
  final String type;
  final bool isNullable;
  final bool isPrimitive;
  final bool isStringContent;
  final ServerReflect? reflect;
  final bool hasToJsonMember;
}
