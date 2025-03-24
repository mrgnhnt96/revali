// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_from_json.dart';
import 'package:revali_client_gen/makers/creators/create_json_case.dart';
import 'package:revali_client_gen/makers/creators/should_decode_json.dart';
import 'package:revali_client_gen/makers/utils/binary_expression_extensions.dart';
import 'package:revali_client_gen/makers/utils/if_statement.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_type.dart';

Code? parseJson(
  ClientType type,
  Expression variable, {
  bool yield = false,
  List<Code> postYieldCode = const [],
}) {
  if (type.isStringContent) {
    return null;
  }

  if (type.isBytes) {
    return null;
  }

  if (shouldDecodeJson(type) case false) {
    final fromJson = switch (createReturnTypeFromJson(type, variable)) {
      final e? when yield => e.yielded.statement,
      final e? => e.returned.statement,
      _ => null,
    };

    if (fromJson == null) {
      return null;
    }

    return Block.of([
      fromJson,
      if (yield && postYieldCode.isNotEmpty) ...[
        const Code(''),
        ...postYieldCode,
      ],
    ]);
  }

  final data = refer('data');

  final body = switch (createReturnTypeFromJson(type, data)) {
    final e? => e,
    _ => data
  };

  return CodeExpression(
    Block.of(
      [
        ifStatement(
          switch (type) {
            ClientType(
              isStream: true,
              typeArguments: [ClientType(isStringContent: true)]
            ) =>
              variable,
            _ => refer('jsonDecode').call([variable]),
          },
          pattern: (
            cse: createJsonCase(type),
            when: null,
          ),
          body: switch (yield) {
            true => Block.of([
                body.yielded.statement,
                if (postYieldCode.isNotEmpty) ...[
                  const Code(''),
                  ...postYieldCode,
                ],
                const Code(''),
                refer('continue').statement,
              ]),
            false => body.returned.statement,
          },
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
