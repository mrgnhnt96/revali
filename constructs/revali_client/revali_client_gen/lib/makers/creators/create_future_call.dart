// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_request.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/makers/utils/create_switch_pattern.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

List<Code> createFutureCall(ClientMethod method) {
  final returnType = method.returnType;

  final coreType = switch (returnType) {
    ClientType(isStream: true, typeArguments: [final type]) ||
    ClientType(isFuture: true, typeArguments: [final type]) => type,
    _ => returnType,
  };

  final fromJson = parseJson(returnType, refer('body'));

  final body = refer('response')
      .property('transform')
      .call([refer('utf8.decoder')])
      .property('join')
      .call([])
      .awaited;

  final bytes = switch (coreType) {
    ClientType(typeArguments: [ClientType(name: 'int')]) =>
      refer('response')
          .property('expand')
          .call([
            Method(
              (b) => b
                ..lambda = true
                ..requiredParameters.add(Parameter((b) => b..name = 'e'))
                ..body = refer('e').code,
            ).closure,
          ])
          .property('toList')
          .call([])
          .awaited,
    _ => refer('response').property('toList').call([]).awaited,
  };

  return [
    createRequest(method),
    const Code(''),
    if (coreType.isVoid)
      ...[]
    else if (coreType.isBytes)
      switch (coreType.isNullable) {
        true => createSwitchPattern(bytes, {
          literal([]): literalNull,
          declareFinal('value'): refer('value'),
        }),
        false => bytes,
      }.returned.statement
    else if (fromJson == null)
      switch (coreType.isNullable) {
        true => createSwitchPattern(body, {
          literalString(''): literalNull,
          declareFinal('value'): refer('value'),
        }).returned.statement,
        false => body.returned.statement,
      }
    else ...[
      declareFinal('body').assign(body).statement,
      const Code(''),
      fromJson,
    ],
  ];
}
