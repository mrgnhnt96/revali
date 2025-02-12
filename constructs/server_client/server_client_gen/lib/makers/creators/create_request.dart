// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/enums/parameter_position.dart';
import 'package:server_client_gen/makers/utils/type_extensions.dart';
import 'package:server_client_gen/models/client_method.dart';

Code createRequest(ClientMethod method) {
  final headers = <String, Code>{};

  for (final param in method.allParams) {
    if (param.position == ParameterPosition.cookie) {
      headers['cookie'] = createMap(
        {
          param.name: refer('_storage')
              .index(literal(param.name))
              .awaited
              .ifNullThen(
                refer((Exception).name)
                    .newInstance(
                      [literal('Missing cookie: ${param.name}')],
                    )
                    .thrown
                    .parenthesized,
              )
              .code,
        },
        ref: (ref) {
          return ref
              .property('entries')
              .property('map')
              .call([
                Method(
                  (b) => b
                    ..lambda = true
                    ..requiredParameters.add(
                      Parameter(
                        (b) => b..name = 'e',
                      ),
                    )
                    ..body = literalString(r'${e.key}=${e.value}').code,
                ).closure,
              ])
              .property('join')
              .call([literal('; ')])
              .code;
        },
      ).code;

      continue;
    }
  }
  return declareFinal('response')
      .assign(
        refer('_client').property('request').call([], {
          'method': refer("'${method.method}'"),
          'path': refer("'${method.resolvedPath}'"),
          if (headers.isNotEmpty) 'headers': createMap(headers),
        }).awaited,
      )
      .statement;
}

Expression createMap(
  Map<String, Code> map, {
  Code Function(Reference)? ref,
}) {
  return CodeExpression(
    Block.of([
      const Code('{'),
      for (final MapEntry(:key, :value) in map.entries) ...[
        literal(key).code,
        const Code(':'),
        value,
        const Code(','),
      ],
      if (ref case final ref?) ref(refer('}')) else const Code('}'),
    ]),
  );
}
