// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_router/revali_router.dart' show WebSocketHandler;
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/convert_to_json.dart';
import 'package:revali_server/makers/creators/create_handler.dart';
import 'package:revali_server/makers/creators/should_nest_json_in_data.dart';
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
    classVarName: 'controller',
    invokeController: false,
    webSocket: null,
    yieldData: true,
    inferredParams: {
      (CloseWebSocket).name: refer('context').property('close'),
      (AsyncWebSocketSender).name: _createAsyncWebSocketSender(returnType),
    },
  );

  return Method(
    (p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..modifier = MethodModifier.async
      ..body = Block.of([
        declareFinal('controller')
            .assign(refer(classVarName).call([]))
            .statement,
        const Code(''),
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

Expression _createAsyncWebSocketSender(ServerType returnType) {
  final data =
      convertToJson(returnType.nonAsyncType, refer('data')) ?? refer('data');
  return refer('${(AsyncWebSocketSender).name}Impl'
          '<${returnType.nonAsyncType.name}>')
      .newInstance([
    Method(
      (b) => b
        ..lambda = true
        ..requiredParameters.add(Parameter((b) => b..name = 'data'))
        ..body = Block.of([
          refer('context').property('asyncSender').property('send').call(
            [
              if (shouldNestJsonInData(returnType) && !returnType.isStream)
                literalMap({'data': data})
              else
                data,
            ],
          ).code,
        ]),
    ).closure,
  ]);
}
