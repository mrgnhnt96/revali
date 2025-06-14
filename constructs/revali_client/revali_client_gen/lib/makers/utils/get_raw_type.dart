import 'package:revali_client_gen/models/client_record_prop.dart';
import 'package:revali_client_gen/models/client_to_json.dart';
import 'package:revali_client_gen/models/client_type.dart';

String getRawType(ClientType type) {
  String data(ClientType type) {
    final map = 'Map${type.isNullable ? '?' : ''}';

    final list = 'List${type.isNullable ? '?' : ''}';

    return switch (type) {
      ClientType(isIterable: true) => list,
      ClientType(isPrimitive: true) => type.name,
      // named records
      ClientType(
        isRecord: true,
        recordProps: [ClientRecordProp(isNamed: true), ...]
      ) =>
        map,
      // at least 1 positional record
      ClientType(isRecord: true) => list,
      ClientType(toJson: ClientToJson(returnType: final type)) =>
        getRawType(type),
      ClientType(isEnum: true) => 'String',
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
