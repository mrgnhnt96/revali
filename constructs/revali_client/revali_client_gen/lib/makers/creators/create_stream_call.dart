// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_request.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/makers/utils/binary_expression_extensions.dart';
import 'package:revali_client_gen/makers/utils/create_switch_pattern.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

List<Code> createStreamCall(ClientMethod method) {
  final returnType = method.returnType.typeForClient;
  if (!returnType.isStream) {
    throw Exception('Stream type expected');
  }

  if (returnType.typeArguments.length != 1) {
    throw Exception('Stream type must have exactly one type argument');
  }

  final typeArgument = returnType.typeArguments.first;
  final body = switch (typeArgument) {
    ClientType(isBytes: true) => refer('response'),
    _ => refer('response').property('transform').call([refer('utf8.decoder')]),
  };

  final fromJson = parseJson(typeArgument, refer('event'));

  Expression mapOver(Expression variable) {
    return variable.property('map').call([
      Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = 'event'))
          ..body = fromJson,
      ).closure,
    ]);
  }

  return [
    createRequest(method),
    const Code(''),
    if (fromJson == null)
      switch (typeArgument.isNullable && typeArgument.isBytes) {
        true => body.property('map').call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((e) => e..name = 'e'))
              ..body = createSwitchPattern(refer('e'), {
                literal([]): literalNull,
                declareFinal('value'): refer('value'),
              }).code,
          ).closure,
        ]),
        false => body,
      }.ignoreError.yieldedStar.statement
    else ...[
      declareFinal('stream').assign(body).statement,
      const Code(''),
      mapOver(refer('stream')).ignoreError.yieldedStar.statement,
    ],
  ];
}

extension _Expression on Expression {
  Expression get ignoreError {
    return property('handleError').call([
      Method(
        (b) => b
          ..requiredParameters.add(Parameter((b) => b..name = '_'))
          ..body = const Code('// do nothing\n'),
      ).closure,
    ]);
  }
}
