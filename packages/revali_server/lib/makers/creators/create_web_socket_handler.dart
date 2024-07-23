import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_router/revali_router.dart' show WebSocketHandler;
import 'package:revali_server/converters/server_return_type.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createWebSocketHandler(
  MetaWebSocketMethod webSocket, {
  required ServerRoute route,
  required ServerReturnType returnType,
  required String classVarName,
}) {
  final onMessage = <Code>[];

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

    onMessage.addAll([
      Code('yield*'),
      stream,
    ]);
  } else if (returnType.isVoid) {
    var invoke =
        refer(classVarName).property(route.handlerName).call(positioned, named);

    if (returnType.isFuture) {
      invoke = invoke.awaited;
    }

    onMessage.add(invoke.statement);
  } else if (returnType.isFuture) {
    final futureResult = declareFinal('result')
        .assign(
          refer(classVarName)
              .property(route.handlerName)
              .call(positioned, named)
              .awaited,
        )
        .statement;

    onMessage.addAll([
      futureResult,
      bodyAssignment,
      Code('yield null;'),
    ]);
  } else {
    final result = declareFinal('result')
        .assign(
          refer(classVarName)
              .property(route.handlerName)
              .call(positioned, named),
        )
        .statement;

    onMessage.addAll([
      result,
      bodyAssignment,
      Code('yield null;'),
    ]);
  }

  return Method(
    (p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..modifier = MethodModifier.async
      ..body = Block.of([
        refer((WebSocketHandler).name)
            .newInstance(
              [],
              {
                'onMessage': Method(
                  (p) => p
                    ..modifier = MethodModifier.asyncStar
                    ..body = Block.of(onMessage),
                ).closure,
              },
            )
            .returned
            .statement,
      ]),
  ).closure;
}
