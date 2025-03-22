// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/convert_to_json.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/makers/creators/should_encode_json.dart';
import 'package:revali_client_gen/makers/utils/binary_expression_extensions.dart';
import 'package:revali_client_gen/makers/utils/client_param_extensions.dart';
import 'package:revali_client_gen/makers/utils/create_switch_pattern.dart';
import 'package:revali_client_gen/makers/utils/for_in_loop.dart';
import 'package:revali_client_gen/makers/utils/if_statement.dart';
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
    if (method.returnType.isVoid case false) ...[
      if ((body, bodyType) case (final body?, final bodyType?)) ...[
        declareVar('hasClosed').assign(literalFalse).statement,
        payloadListener(bodyType, refer(body.name)),
        const Code(''),
      ],
      channel(
        method.returnType,
        includeHasClosed: (body, bodyType) != (null, null),
      ).code,
      const Code(''),
      if (body case Object()) ...[
        refer('payloadListener').property('cancel').call([]).awaited.statement,
      ],
    ],
  ];
}

Code payloadListener(ClientType type, Expression variable) {
  final encode = encodeJson(type, 'e');

  var assignment = variable;

  if (encode != null) {
    assignment = assignment.property('map').call([
      Method(
        (b) => b
          ..lambda = true
          ..requiredParameters.add(Parameter((b) => b..name = 'e'))
          ..body = refer('utf8').property('encode').call([encode]).code,
      ).closure,
    ]);
  }

  return declareFinal('payloadListener')
      .assign(
        assignment.property('listen').call([
          refer('channel').property('sink').property('add'),
        ], {
          'onDone': Method(
            (b) => b
              ..body = Block.of([
                refer('hasClosed').assign(literalTrue).statement,
                refer('channel')
                    .property('sink')
                    .property('close')
                    .call([]).statement,
              ]),
          ).closure,
          'cancelOnError': literalTrue,
        }),
      )
      .statement;
}

Expression? encodeJson(ClientType type, String variable) {
  final toJson = convertToJson(type, refer(variable));

  final shouldEncode = shouldEncodeJson(type);

  if (shouldEncode == null) {
    return null;
  }

  if (shouldEncode case false) {
    return toJson;
  }

  return refer('jsonEncode').call([toJson ?? refer(variable)]);
}

Expression channel(ClientType type, {required bool includeHasClosed}) {
  final channel = refer('channel').property('stream');
  final event = refer('utf8').property('decode').call([refer('event')]);

  final hasClosed = ifStatement(
    refer('hasClosed'),
    body: refer('break').statement,
  ).code;

  final fromJson = parseJson(
    type,
    event,
    yield: true,
    postYieldCode: [if (includeHasClosed) hasClosed],
  );

  if (fromJson == null && type.isBytes) {
    return CodeExpression(
      switch (type) {
        ClientType(typeArguments: [ClientType(isNullable: true)]) =>
          channel.property('map').call([
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
        _ => channel.property('cast').call([]),
      }
          .yieldedStar
          .statement,
    );
  }

  return forInLoop(
    declaration: declareFinal('event'),
    iterable: channel,
    body: switch (type) {
      ClientType(isStringContent: true, :final isNullable) ||
      ClientType(
        typeArguments: [ClientType(isStringContent: true, :final isNullable)]
      )
          when fromJson == null =>
        switch (isNullable) {
          true => Block.of([
              ifStatement(
                refer('event'),
                pattern: (cse: literal([]), when: null),
                body: Block.of([
                  literalNull.yielded.statement,
                  refer('continue').statement,
                ]),
              ).code,
              const Code(''),
              event.yielded.statement,
              if (includeHasClosed) ...[
                const Code(''),
                hasClosed,
              ],
            ]),
          false => Block.of([
              event.yielded.statement,
              if (includeHasClosed) ...[
                const Code(''),
                hasClosed,
              ],
            ]),
        },
      _ => fromJson,
    },
  ).awaited;
}
