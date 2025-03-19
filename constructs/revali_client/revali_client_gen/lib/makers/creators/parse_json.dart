// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_from_json.dart';
import 'package:revali_client_gen/makers/creators/create_json_case.dart';
import 'package:revali_client_gen/makers/creators/should_decode_json.dart';
import 'package:revali_client_gen/makers/utils/if_statement.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_type.dart';

Code? parseJson(ClientType type, Expression variable) {
  if (type.isStringContent) {
    return null;
  }

  if (shouldDecodeJson(type) case false) {
    final fromJson = switch (createReturnTypeFromJson(type, variable)) {
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
              variable,
            _ => refer('jsonDecode').call([variable]),
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
