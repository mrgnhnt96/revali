// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/convert_to_json.dart';
import 'package:revali_server/makers/creators/create_web_socket_handler.dart';
import 'package:revali_server/makers/creators/should_nest_json_in_data.dart';
import 'package:revali_server/makers/utils/get_params.dart';

Expression? createHandler({
  required ServerRoute route,
  required ServerType? returnType,
  required String? classVarName,
  required MetaWebSocketMethod? webSocket,
  List<Code> additionalHandlerCode = const [],
}) {
  if (returnType == null || classVarName == null) {
    return null;
  }

  if (webSocket != null) {
    return createWebSocketHandler(
      webSocket,
      route: route,
      returnType: returnType,
      classVarName: classVarName,
    );
  }

  var handler = literalNull;

  final (:positioned, :named) = getParams(route.params);
  handler =
      refer(classVarName).property(route.handlerName).call(positioned, named);

  if (returnType.isFuture) {
    handler = handler.awaited;
  }

  Expression? setBody;
  if (returnType case ServerType(isVoid: false)) {
    handler = declareFinal('result').assign(handler);

    setBody = refer('context').property('response').property('body');

    final json = convertToJson(returnType, refer('result')) ?? refer('result');

    if (shouldNestJsonInData(returnType) && !returnType.isStream) {
      setBody = setBody.index(literalString('data')).assign(json);
    } else {
      setBody = setBody.assign(json);
    }
  }

  return Method(
    (p) => p
      ..requiredParameters.add(Parameter((b) => b..name = 'context'))
      ..modifier = MethodModifier.async
      ..body = Block.of([
        if (route.params.any((e) => e.annotations.body != null))
          refer('context')
              .property('request')
              .property('resolvePayload')
              .call([])
              .awaited
              .statement,
        const Code('\n'),
        ...additionalHandlerCode,
        const Code('\n'),
        handler.statement,
        if (setBody != null) ...[
          const Code('\n'),
          setBody.statement,
        ],
      ]),
  ).closure;
}
