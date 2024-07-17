import 'package:code_builder/code_builder.dart';
import 'package:revali_server/revali_server.dart';

Map<String, Expression> createRouteArgs({
  required ServerRoute route,
  ServerReturnType? returnType,
  String? classVarName,
  String? method,
  int? statusCode,
  List<Code> additionalHandlerCode = const [],
}) {
  var handler = literalNull;

  if (returnType != null && classVarName != null) {
    final (:positioned, :named) = getParams(route.params);
    handler =
        refer(classVarName).property(route.handlerName).call(positioned, named);

    if (returnType.isFuture) {
      handler = handler.awaited;
    }

    if (!returnType.isVoid) {
      handler = declareFinal('result').assign(handler);
    }
  }

  Expression? setBody;
  if (returnType != null && !returnType.isVoid) {
    Expression result = refer('result');
    if (returnType.hasToJsonMember) {
      result = result.property('toJson').call([]);
    }

    if (returnType.isPrimitive || returnType.hasToJsonMember) {
      result = literalMap({
        'data': result,
      });
    }

    setBody =
        refer('context').property('response').property('body').assign(result);
  }

  return {
    ...createModifierArgs(annotations: route.annotations),
    if (method != null) 'method': literalString(method),
    if ('$handler' != '$literalNull')
      'handler': Method(
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
            Code('\n'),
            ...additionalHandlerCode,
            Code('\n'),
            handler.statement,
            if (setBody != null) ...[
              Code('\n'),
              setBody.statement,
            ],
          ]),
      ).closure,
  };
}
