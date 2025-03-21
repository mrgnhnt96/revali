import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/models/client_type.dart';

Reference createReturnType(ClientType type) {
  return TypeReference(
    (b) => b
      ..symbol = switch (type) {
        ClientType(isStream: true) => 'Stream',
        ClientType(isFuture: true) => 'Future',
        ClientType(isMap: true) => 'Map',
        ClientType(:final iterableType?) => iterableType.symbol,
        ClientType(isStringContent: true, isNullable: true) => 'String?',
        ClientType(isStringContent: true) => 'String',
        ClientType(:final name) => name,
      }
      ..types.addAll([
        if (type case ClientType(typeArguments: final types))
          for (final type in types) createReturnType(type),
      ]),
  );
}
