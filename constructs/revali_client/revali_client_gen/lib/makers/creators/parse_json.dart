// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_from_json.dart';
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
      Block.of([
        refer(variable).returned.statement,
      ]),
    );
  }

  return CodeExpression(
    Block.of(
      [
        ifStatement(
          refer('jsonDecode').call([refer(variable)]),
          pattern: (
            cse: switch (method.returnType) {
              final e when e.isIterable && e.isStream =>
                declareFinal('data', type: refer('List<dynamic>')),
              final e when e.isStream && !method.isWebsocket => declareFinal(
                  'data',
                  type: switch (method.returnType) {
                    final e when e.isPrimitive => refer(e.resolvedName),
                    _ => refer('Map<dynamic, dynamic>'),
                  },
                ),
              _ => literalMap({
                  'data': declareFinal(
                    'data',
                    type: switch (method.returnType) {
                      final e when e.isIterable => refer('List<dynamic>'),
                      final e when e.isPrimitive => refer(e.fullName),
                      _ => refer('Map<dynamic, dynamic>'),
                    },
                  ),
                }),
            },
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
                        final e when e.hasFromJson => createFromJson(
                            e,
                            'e',
                            forceMapType: true,
                          ),
                        _ => refer('e'),
                      }
                          .code,
                  ).closure,
                ])
                .property('toList')
                .call([]),
            final e when e.hasFromJson => createFromJson(e, 'data'),
            final e when e.isPrimitive => refer('data'),
            _ => refer('data'),
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
