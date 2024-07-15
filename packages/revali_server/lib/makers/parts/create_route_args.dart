import 'package:code_builder/code_builder.dart';
import 'package:revali_server/makers/parts/create_modifier_args.dart';
import 'package:revali_server/makers/parts/get_params.dart';
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
          ]),
      ).closure,
  };
}
