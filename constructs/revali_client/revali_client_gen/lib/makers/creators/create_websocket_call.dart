// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/convert_to_json.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/makers/creators/should_decode_json.dart';
import 'package:revali_client_gen/makers/utils/binary_expression_extensions.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/makers/utils/create_switch_pattern.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

List<Code> createWebsocketCall(ClientMethod method) {
  final (
    body: _,
    query: queries,
    headers: _,
    cookies: _,
  ) = method.parameters.separate;

  final body = method.websocketBody;
  final bodyType = switch (body?.type) {
    ClientType(isStream: true, typeArguments: [final type]) => type,
    null => null,
    _ => throw Exception('Invalid body type'),
  };

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
          refer('_websocket').call(
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
    if ((body, bodyType) case (final body?, final bodyType?)) ...[
      declareFinal('payloadListener')
          .assign(
            refer(body.name)
                .property('map')
                .call([
                  if (encodeJson(bodyType, 'e') case final encode?)
                    Method(
                      (b) => b
                        ..lambda = true
                        ..requiredParameters
                            .add(Parameter((b) => b..name = 'e'))
                        ..body = refer('utf8')
                            .property('encode')
                            .call([encode]).code,
                    ).closure
                  else
                    refer('utf8').property('encode'),
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
    channel(method.returnType).yieldedStar.statement,
    const Code(''),
    if (body case Object()) ...[
      refer('payloadListener').property('cancel').call([]).awaited.statement,
    ],
  ];
}

Expression? encodeJson(ClientType type, String variable) {
  final toJson = convertToJson(type, refer(variable));

  if (shouldDecodeJson(type) case false) {
    return toJson;
  }

  return refer('jsonEncode').call([toJson ?? refer(variable)]);
}

Expression channel(ClientType type) {
  final channel = refer('channel').property('stream');

  final event = switch (type) {
    ClientType(isStringContent: true) => refer('event'),
    _ => refer('utf8').property('decode').call([refer('event')]),
  };

  final fromJson = parseJson(type, event);

  if (fromJson == null) {
    return channel.property('cast').call([]);
  }

  return channel.property('map').call(
    [
      Method(
        (b) => b
          ..requiredParameters.add(
            Parameter((b) => b..name = 'event'),
          )
          ..body = fromJson,
      ).closure,
    ],
  );
}
