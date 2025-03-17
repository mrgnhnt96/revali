// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_from_json.dart';
import 'package:revali_client_gen/makers/creators/create_json_case.dart';
import 'package:revali_client_gen/makers/utils/if_statement.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_method.dart';

Expression parseJson(ClientMethod method, String variable) {
  if (method.returnType.isStringContent) {
    return CodeExpression(
      Block.of([
        refer(variable).returned.statement,
      ]),
    );
  }

  if (method.returnType.isStream && method.returnType.isPrimitive) {
    final fromJson = switch (
        createReturnTypeFromJson(method.returnType, refer(variable))) {
      final e? => e,
      _ => refer(variable)
    };

    return CodeExpression(fromJson.returned.statement);
  }

  return CodeExpression(
    Block.of(
      [
        ifStatement(
          refer('jsonDecode').call([refer(variable)]),
          pattern: (
            cse: createJsonCase(method.returnType),
            when: null,
          ),
          body: switch (
                  createReturnTypeFromJson(method.returnType, refer('data'))) {
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
  );
}
