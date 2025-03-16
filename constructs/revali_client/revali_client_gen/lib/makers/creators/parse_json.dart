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
    return CodeExpression(
      createReturnTypeFromJson(method.returnType, refer(variable))
          .returned
          .statement,
    );
  }

  return CodeExpression(
    Block.of(
      [
        ifStatement(
          refer('jsonDecode').call([refer(variable)]),
          pattern: (
            cse: createJsonCase(
              method.returnType,
              isWebsocket: method.isWebsocket,
            ),
            when: null,
          ),
          body: createReturnTypeFromJson(method.returnType, refer('data'))
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
