// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_router/revali_router.dart' show WebSocketHandler;
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createWebSocketHandler(
  MetaWebSocketMethod webSocket, {
  required ServerRoute route,
  required ServerType returnType,
  required String classVarName,
}) {
  final trigger = <Code>[];

  final bodyAssignment = refer('context')
      .property('response')
      .property('body')
      .index(literalString('data'))
      .assign(refer('result'))
      .statement;

  final (:positioned, :named) = getParams(route.params);

  if (returnType.isStream) {
    final stream = refer(classVarName)
        .property(route.handlerName)
        .call(positioned, named)
        .property('asyncMap')
        .call([
      Method(
        (p) => p
          ..requiredParameters.add(Parameter((b) => b..name = 'result'))
          ..body = Block.of([bodyAssignment]),
      ).closure,
    ]).statement;

    trigger.addAll([
      const Code('yield*'),
      stream,
    ]);
  } else if (returnType.isVoid) {
    var invoke =
        refer(classVarName).property(route.handlerName).call(positioned, named);

    if (returnType.isFuture) {
      invoke = invoke.awaited;
    }

    trigger.add(invoke.statement);
  } else if (returnType.isFuture) {
    final futureResult = declareFinal('result')
        .assign(
          refer(classVarName)
              .property(route.handlerName)
              .call(positioned, named)
              .awaited,
        )
        .statement;

    trigger.addAll([
      futureResult,
      bodyAssignment,
      const Code('yield null;'),
    ]);
  } else {
    final result = declareFinal('result')
        .assign(
          refer(classVarName)
              .property(route.handlerName)
              .call(positioned, named),
        )
        .statement;

    trigger.addAll([
      result,
      bodyAssignment,
      const Code('yield null;'),
    ]);
  }
  final handler = Method(
    (p) => p
      ..modifier = MethodModifier.asyncStar
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..body = Block.of(trigger),
  ).closure;

  return Method(
    (p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..modifier = MethodModifier.async
      ..body = Block.of([
        refer((WebSocketHandler).name)
            .newInstance(
              [],
              {
                if (webSocket.triggerOnConnect || !webSocket.mode.canReceive)
                  'onConnect': handler,
                if (webSocket.mode.canReceive) 'onMessage': handler,
              },
            )
            .returned
            .statement,
      ]),
  ).closure;
}
