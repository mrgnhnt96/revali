// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_body_arg.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/makers/utils/binary_expression_extensions.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/makers/utils/create_switch_pattern.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_param.dart';

List<Code> createWebsocketCall(ClientMethod method) {
  final (
    body: bodyParts,
    query: queries,
    headers: _,
    cookies: _,
  ) = method.parameters.separate;

  ClientParam? body;
  if (method.websocketType.canSendAny) {
    final roots = bodyParts.roots();
    for (final e in bodyParts) {
      if (!bodyParts.needsAssignment(e, roots)) {
        continue;
      }

      if (body != null) {
        throw Exception(
          'Cannot have multiple body params for a WebSocket call',
        );
      }

      body = e;
    }
  }

  StringBuffer? queryBuffer;
  for (final param in queries) {
    queryBuffer ??= StringBuffer('?');

    queryBuffer.write('${param.name}=\${${param.name}}');
  }
  final query = queryBuffer?.toString() ?? '';

  final path = method.resolvedPath + query;

  return [
    declareFinal('baseUrl')
        .assign(
          createSwitchPattern(
            refer('_storage').index(literal('__BASE_URL__')).awaited,
            {
              declareFinal('url', type: refer((String).name)):
                  refer('url').property('replaceAll').call(
                [
                  refer((RegExp).name).newInstance([
                    literal('^https?'),
                  ]),
                  literal('ws'),
                ],
              ),
              const Code('_'): refer('Exception').newInstance([
                literal('Base URL not set'),
              ]).thrown,
            },
          ),
        )
        .statement,
    const Code(''),
    declareFinal('channel')
        .assign(
          refer('WebSocketChannel').newInstanceNamed(
            'connect',
            [
              refer((Uri).name).newInstanceNamed(
                'parse',
                [refer(r"'$baseUrl" "$path'")],
              ),
            ],
          ),
        )
        .statement,
    refer('channel').property('ready').awaited.statement,
    const Code(''),
    if (body case final body?) ...[
      declareFinal('payloadListener')
          .assign(
            refer(body.name)
                .property('map')
                .call([
                  Method(
                    (b) => b
                      ..lambda = true
                      ..requiredParameters
                          .add(Parameter((b) => b..name = body.name))
                      ..body = refer('utf8').property('encode').call([
                        refer('jsonEncode').call([
                          createBodyArg([body]),
                        ]),
                      ]).code,
                  ).closure,
                ])
                .property('listen')
                .call([
                  refer('channel').property('sink').property('add'),
                ], {
                  'onDone': refer('channel').property('sink').property('close'),
                  'cancelOnError': literalTrue,
                }),
          )
          .statement,
      const Code(''),
    ],
    refer('channel')
        .property('stream')
        .property('map')
        .call(
          [
            Method(
              (b) => b
                ..requiredParameters.add(
                  Parameter((b) => b..name = 'event'),
                )
                ..body = Block.of([
                  declareFinal('json')
                      .assign(
                        createSwitchPattern(
                          refer('event'),
                          {
                            const Code('String()'): refer('event'),
                            const Code('List<int>()'):
                                refer('utf8').property('decode').call([
                              refer('List<int>')
                                  .newInstanceNamed('from', [refer('event')]),
                            ]),
                            const Code('_'):
                                refer('UnsupportedError').newInstance(
                              [
                                literalString(
                                  'Unsupported message type: '
                                  r'${event.runtimeType}',
                                ),
                              ],
                            ).thrown,
                          },
                        ),
                      )
                      .statement,
                  if (parseJson(method.returnType, 'json')
                      case final parsed?) ...[
                    const Code(''),
                    parsed,
                  ],
                ]),
            ).closure,
          ],
        )
        .yieldedStar
        .statement,
    const Code(''),
    if (body case Object()) ...[
      refer('payloadListener').property('cancel').call([]).awaited.statement,
    ],
  ];
}
