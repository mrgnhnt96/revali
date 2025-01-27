import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/class_element_extensions.dart';

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
    required this.hasFromJsonMember,
    required this.isStringContent,
    required this.isMap,
    required this.isIterable,
    required this.isIterableNullable,
  });

  factory ServerReturnType.fromMeta(MetaReturnType type) {
    ServerReflect? reflect;
    var hasToJsonMember = false;
    var hasFromJsonMember = false;
    var isStringContent = false;
    var isIterableNullable = false;

    if (type.resolvedElement case final element?) {
      reflect = ServerReflect.fromElement(element);

      if (type.isIterable) {
        if (type.typeArguments.isNotEmpty) {
          var (_, typeArg) = type.typeArguments.first;

          while (typeArg is InterfaceType && typeArg.typeArguments.isNotEmpty) {
            final isIterable = typeArg.allSupertypes.any(
              (e) => e
                  .getDisplayString()
                  // ignore: unnecessary_parenthesis
                  .startsWith((Iterable).name),
            );

            if (!isIterable) {
              break;
            }

            typeArg = typeArg.typeArguments.first;
          }

          if (typeArg is InterfaceType) {
            isIterableNullable =
                typeArg.nullabilitySuffix != NullabilitySuffix.none;
          }
        }
      }

      if (element is ClassElement) {
        hasToJsonMember = element.methods.any((e) => e.name == 'toJson');
        hasFromJsonMember = element.hasFromJsonMember;
        // ignore: unnecessary_parenthesis
        isStringContent = element.name == (StringContent).name ||
            element.allSupertypes.any(
              (e) =>
                  e.getDisplayString() ==
                  // ignore: unnecessary_parenthesis
                  (StringContent).name,
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
      hasFromJsonMember: hasFromJsonMember,
      isStringContent: isStringContent,
      isMap: type.isMap,
      isIterable: type.isIterable,
      isIterableNullable: isIterableNullable,
    );
  }

  final bool isVoid;
  final bool isFuture;
  final bool isStream;
  final bool isIterable;
  final String type;
  final bool isNullable;
  final bool isIterableNullable;
  final bool isPrimitive;
  final bool isStringContent;
  final ServerReflect? reflect;
  final bool hasToJsonMember;
  final bool hasFromJsonMember;
  final bool isMap;
}
