// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_from_json.dart';
import 'package:revali_client_gen/makers/creators/create_json_case.dart';
import 'package:revali_client_gen/makers/utils/if_statement.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_type.dart';

Code? parseJson(ClientType type, String variable) {
  if (type.isStringContent) {
    return null;
  }

  if (shouldDecodeJson(type) case false) {
    final fromJson = switch (createReturnTypeFromJson(type, refer(variable))) {
      final e? => e.returned.statement,
      _ => null,
    };

    return fromJson;
  }

  return CodeExpression(
    Block.of(
      [
        ifStatement(
          switch (type) {
            ClientType(
              isStream: true,
              typeArguments: [ClientType(isPrimitive: true)]
            ) =>
              refer(variable),
            _ => refer('jsonDecode').call([refer(variable)]),
          },
          pattern: (
            cse: createJsonCase(type),
            when: null,
          ),
          body: switch (createReturnTypeFromJson(type, refer('data'))) {
            final e? => e,
            _ => refer('data')
          }
              .returned
              .statement,
        ).code,
        const Code(''),
        refer((Exception).name)
            .newInstance([
              literalString('Invalid response'),
            ])
            .thrown
            .statement,
      ],
    ),
  ).code;
}

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
    ClientType(hasFromJsonConstructor: true) => true,
    ClientType(isRecord: true) => true,
    ClientType(root: ClientType(isStream: true)) => false,
    ClientType(isStringContent: true) => false,
    ClientType(isDynamic: true) => false,
    _ => null,
  };
}
