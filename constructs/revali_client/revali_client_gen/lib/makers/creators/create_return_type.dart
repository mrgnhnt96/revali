import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

Reference createReturnType(ClientType type) {
  return TypeReference(
    (b) => b
      ..symbol = switch (type) {
        ClientType(isStream: true) => 'Stream',
        ClientType(isFuture: true, method: ClientMethod(isWebsocket: true)) =>
          'Stream',
        ClientType(isFuture: true) => 'Future',
        ClientType(isMap: true) => 'Map',
        ClientType(:final iterableType?) => iterableType.symbol,
        ClientType(isStringContent: true) => 'String',
        ClientType(:final name) => name.replaceAll(RegExp(r'\?$'), ''),
      }
      ..isNullable = type.isNullable
      ..types.addAll([
        if (type case ClientType(typeArguments: final types))
          for (final type in types) createReturnType(type),
      ]),
  );
}
