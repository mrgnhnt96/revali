// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/if_statement.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_param.dart';

Code createCookieHeader(Iterable<ClientParam> params) {
  assert(params.isNotEmpty, 'No cookie params found');
  assert(
    params.every((param) => param.position == ParameterPosition.cookie),
    'Not all params are cookie params',
  );

  return Block.of([
    const Code('{'),
    for (final entry in params.map(_createEntry)) ...[entry, const Code(',')],
    refer('}')
        .property('entries')
        .property('map')
        .call([
          Method(
            (b) => b
              ..lambda = true
              ..requiredParameters.add(Parameter((b) => b..name = 'e'))
              ..body = literalString(r'${e.key}=${e.value ?? ""}').code,
          ).closure,
        ])
        .property('join')
        .call([literal('; ')])
        .code,
  ]);
}

Code _createEntry(ClientParam param) {
  final access = switch (param.access) {
    [final String access] => access,
    _ => param.name,
  };

  var cookie = refer('_storage').index(literal(access)).awaited;

  if (param.type.isNullable) {
    return ifStatement(
      cookie,
      pattern: (
        cse: declareFinal('value', type: refer(param.type.nonNullName)),
        when: null,
      ),
      blockBody: false,
      body: Block.of([Code("'$access'"), const Code(':'), refer('value').code]),
    ).code;
  } else {
    cookie = cookie.ifNullThen(
      refer(
        (Exception).name,
      ).newInstance([literal('Missing cookie: $access')]).thrown.parenthesized,
    );
  }

  return Block.of([Code("'$access'"), const Code(':'), cookie.code]);
}
