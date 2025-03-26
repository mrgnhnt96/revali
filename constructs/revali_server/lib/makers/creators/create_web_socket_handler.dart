// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_router/revali_router.dart' show WebSocketHandler;
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/create_handler.dart';
import 'package:revali_server/makers/utils/binary_expression_extensions.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createWebSocketHandler(
  MetaWebSocketMethod webSocket, {
  required ServerRoute route,
  required ServerType returnType,
  required String classVarName,
}) {
  final handler = createHandler(
    route: route,
    returnType: returnType,
    classVarName: classVarName,
    webSocket: null,
    postBodyCode: [
      literalNull.yielded.statement,
    ],
    inferredParams: {
      (CloseWebSocket).name: refer('context').property('close'),
    },
  );

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
