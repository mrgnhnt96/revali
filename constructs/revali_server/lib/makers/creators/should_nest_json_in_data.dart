import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_type.dart';

bool shouldNestJsonInData(ServerType returnType) {
  if (returnType.isStream) {
    return false;
  }

  final type = switch (returnType) {
    ServerType(isFuture: true, typeArguments: [final type]) => type,
    _ => returnType,
  };

  // List<int>
  if (type
      case ServerType(
        iterableType: IterableType.list,
        typeArguments: [
          ServerType(name: 'int'),
        ],
      )) {
    return false;
  }

  // List<List<int>>
  if (type
      case ServerType(
        iterableType: IterableType.list,
        typeArguments: [
          ServerType(
            iterableType: IterableType.list,
            typeArguments: [
              ServerType(isPrimitive: true),
            ],
          ),
        ],
      )) {
    return false;
  }

  if (type.isStringContent) {
    return false;
  }

  return true;
}
