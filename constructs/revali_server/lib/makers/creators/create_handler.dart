// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_child_route.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/convert_to_json.dart';
import 'package:revali_server/makers/creators/create_class.dart';
import 'package:revali_server/makers/creators/create_web_socket_handler.dart';
import 'package:revali_server/makers/creators/should_nest_json_in_data.dart';
import 'package:revali_server/makers/utils/binary_expression_extensions.dart';
import 'package:revali_server/makers/utils/get_params.dart';

Expression createHandler({
  required ServerRoute route,
  required ServerType returnType,
  required String classVarName,
  required MetaWebSocketMethod? webSocket,
  bool yieldData = false,
  bool invokeController = true,
  List<Code> additionalHandlerCode = const [],
  Map<String, Expression> inferredParams = const {},
}) {
  if (webSocket != null) {
    return createWebSocketHandler(
      webSocket,
      route: route,
      returnType: returnType,
      classVarName: classVarName,
    );
  }

  var handler = literalNull;

  final (:positioned, :named) = getParams(
    route.params,
    inferredParams: inferredParams,
  );
  handler = refer(classVarName);
  if (invokeController) {
    handler = handler.call([]);
  }

  handler = handler.property(route.handlerName).call(positioned, named);

  if (returnType.isFuture) {
    handler = handler.awaited;
  }

  final responseBody = refer('context').property('response').property('body');

  Expression? data;
  if (returnType case ServerType(isVoid: false)) {
    handler = declareFinal('result').assign(handler);

    final json = convertToJson(returnType, refer('result')) ?? refer('result');

    if (shouldNestJsonInData(returnType) && !returnType.isStream) {
      data = literalMap({'data': json});
    } else {
      data = json;
    }
  }

  return Method(
    (p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..modifier = switch (returnType.route) {
        ServerChildRoute(isWebSocket: true) => MethodModifier.asyncStar,
        _ => MethodModifier.async,
      }
      ..body = Block.of([
        if (route.params.any((e) => e.annotations.body != null))
          refer('context')
              .property('request')
              .property('resolvePayload')
              .call([])
              .awaited
              .statement,
        const Code('\n'),
        if (route.pipes case final pipes when pipes.isNotEmpty) ...[
          for (final pipe in pipes)
            declareFinal(pipe.clazz.variableName)
                .assign(createClass(pipe.clazz))
                .statement,
          const Code('\n'),
        ],
        ...additionalHandlerCode,
        const Code('\n'),
        handler.statement,
        if (data != null) ...[
          const Code('\n'),
          if (yieldData)
            switch (returnType.isStream) {
              true => data.yieldedStar.statement,
              false => data.yielded.statement,
            }
          else
            responseBody.assign(data).statement,
        ],
      ]),
  ).closure;
}
