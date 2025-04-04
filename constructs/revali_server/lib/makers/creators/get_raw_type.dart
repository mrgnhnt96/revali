import 'package:revali_server/converters/server_from_json.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_type.dart';

String getRawType(ServerType type) {
  String data(ServerType type) {
    final map = 'Map${type.isNullable ? '?' : ''}';

    final list = 'List${type.isNullable ? '?' : ''}';

    return switch (type) {
      ServerType(isIterable: true) => list,
      ServerType(isPrimitive: true) => type.name,
      // named records
      ServerType(
        isRecord: true,
        recordProps: [ServerRecordProp(isNamed: true), ...]
      ) =>
        map,
      // at least 1 positional record
      ServerType(isRecord: true) => list,
      ServerType(fromJson: ServerFromJson(params: [final type])) =>
        getRawType(type),
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
