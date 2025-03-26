import 'package:revali_client_gen/models/client_type.dart';

bool? shouldDecodeJson(ClientType type) {
  if (type.isStream) {
    if (type.typeArguments.length != 1) {
      throw Exception('Stream must have exactly one type argument');
    }

    return shouldDecodeJson(type.typeArguments.first);
  }

  if (type.isIterable) {
    if (type.typeArguments.length != 1) {
      throw Exception('Iterable must have exactly one type argument');
    }

    return shouldDecodeJson(type.typeArguments.first);
  }

  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Future must have exactly one type argument');
    }

    return shouldDecodeJson(type.typeArguments.first);
  }

  return switch (type) {
    ClientType(isMap: true) => true,
    ClientType(isPrimitive: true, isBytes: false) => true,
    ClientType(hasFromJson: true) => true,
    ClientType(isRecord: true) => true,
    ClientType(isStringContent: true) => false,
    ClientType(isDynamic: true) => false,
    ClientType(isBytes: true) => false,
    _ => null,
  };
}
