// ignore_for_file: unnecessary_parenthesis

import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_server/converters/server_from_json.dart';
import 'package:revali_server/converters/server_record_prop.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

String getRawType(ServerType type) {
  String iterableRawType(ServerType type) {
    final base = switch (type.iterableType) {
      IterableType.set => 'Set',
      IterableType.iterable => 'Iterable',
      IterableType.list || null => 'List',
    };

    if (type.typeArguments.isEmpty) {
      return '$base${type.isNullable ? '?' : ''}';
    }

    final args = type.typeArguments.map(getRawType).join(', ');
    return '$base<$args>${type.isNullable ? '?' : ''}';
  }

  String data(ServerType type) {
    final map = 'Map${type.isNullable ? '?' : ''}';

    return switch (type) {
      ServerType(isIterable: true) => iterableRawType(type),
      ServerType(isPrimitive: true) => type.name,
      // named records
      ServerType(
        isRecord: true,
        recordProps: [ServerRecordProp(isNamed: true), ...],
      ) =>
        map,
      // at least 1 positional record
      ServerType(isRecord: true) => 'List${type.isNullable ? '?' : ''}',
      ServerType(fromJson: ServerFromJson(params: [final type])) => getRawType(
        type,
      ),
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

  if (type.isEnum) {
    return (String).name;
  }

  return data(type);
}
