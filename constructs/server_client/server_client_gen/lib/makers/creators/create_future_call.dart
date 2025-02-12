// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/utils/if_statement.dart';
import 'package:server_client_gen/makers/utils/type_extensions.dart';
import 'package:server_client_gen/models/client_method.dart';
import 'package:server_client_gen/models/client_return_type.dart';

List<Code> createFutureCall(ClientMethod method) {
  return [
    declareFinal('response')
        .assign(
          refer('_client').property('request').call([], {
            'method': refer("'${method.method}'"),
            'path': refer("'${method.fullPath}'"),
          }).awaited,
        )
        .statement,
    const Code(''),
    declareFinal('body')
        .assign(
          refer('response')
              .property('transform')
              .call([refer('utf8.decoder')])
              .property('join')
              .call([])
              .awaited,
        )
        .statement,
    const Code(''),
    ifStatement(
      refer('jsonDecode').call([refer('body')]),
      pattern: (
        cse: literalMap({
          'data': declareFinal(
            'data',
            type: switch (method.returnType) {
              final e when e.isIterable => refer('List<dynamic>'),
              final e when e.isPrimitive => refer(e.fullName),
              _ => refer('Map<dynamic, dynamic>'),
            },
          ),
        }),
        when: null,
      ),
      body: switch (method.returnType) {
        final e when e.isIterable => refer('data')
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
                  ..body = switch (method.returnType) {
                    final e when e.isPrimitive => refer('e'),
                    final e when e.hasFromJson => createFromJson(e),
                    _ => refer('data'),
                  }
                      .code,
              ).closure,
            ])
            .property('toList')
            .call([]),
        final e when e.hasFromJson => createFromJson(e),
        final e when e.isPrimitive => refer('data'),
        _ => refer('data'),
      }
          .returned
          .statement,
    ).code,
    const Code(''),
    refer('throw').code,
    refer((Exception).name).newInstance([
      literalString('Invalid response'),
    ]).statement,
  ];
}

Expression createFromJson(ClientReturnType method) {
  return refer(method.resolvedName)
      .newInstanceNamed('fromJson', [refer('data').property('cast').call([])]);
}
