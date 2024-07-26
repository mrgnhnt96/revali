import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_server/converters/server_return_type.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/makers/creators/create_web_socket_handler.dart';
import 'package:revali_server/makers/utils/get_params.dart';

Expression? createHandler({
  required ServerRoute route,
  required ServerReturnType? returnType,
  required String? classVarName,
  required MetaWebSocketMethod? webSocket,
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

  if (!returnType.isVoid) {
    handler = declareFinal('result').assign(handler);
  }

  Expression? setBody;
  if (!returnType.isVoid) {
    Expression result = refer('result');

    if (returnType.hasToJsonMember) {
      if (returnType.isNullable) {
        result = result.nullSafeProperty('toJson').call([]);
      } else {
        result = result.property('toJson').call([]);
      }
    }

    setBody = refer('context').property('response').property('body');

    if (returnType.isPrimitive ||
        returnType.hasToJsonMember ||
        returnType.isMap) {
      setBody = setBody.index(literalString('data')).assign(result);
    } else if (returnType.isStringContent) {
      result = result.property('value');
      setBody = setBody.assign(result);
    } else {
      setBody = setBody.assign(result);
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
        const Code('\n'),
        handler.statement,
        if (setBody != null) ...[
          const Code('\n'),
          setBody.statement,
        ],
      ]),
  ).closure;
}
