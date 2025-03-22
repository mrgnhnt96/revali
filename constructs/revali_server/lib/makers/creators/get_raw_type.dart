import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_type.dart';

Reference getRawType(ServerType type) {
  Reference data(ServerType type) {
    final map = TypeReference(
      (b) => b..symbol = 'Map${type.isNullable ? '?' : ''}',
    );

    final list = TypeReference(
      (b) => b..symbol = 'List${type.isNullable ? '?' : ''}',
    );

    return switch (type) {
      ServerType(isIterable: true) => list,
      ServerType(isPrimitive: true) => refer(type.name),
      // named records
      ServerType(
        isRecord: true,
        recordProps: [ServerRecordProp(isNamed: true), ...]
      ) =>
        map,
      // at least 1 positional record
      ServerType(isRecord: true) => list,
      _ => map,
    };
  }

  if (type.isStream) {
    if (type.typeArguments.length != 1) {
      throw Exception('Stream must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return getRawType(typeArgument);
  }

  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Future must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return getRawType(typeArgument);
  }

  return data(type);
}
