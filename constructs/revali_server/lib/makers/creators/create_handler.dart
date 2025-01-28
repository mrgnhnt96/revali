// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_child_route.dart';
import 'package:revali_server/converters/server_return_type.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';
import 'package:revali_server/makers/creators/create_web_socket_handler.dart';
import 'package:revali_server/makers/utils/get_params.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression? createHandler({
  required ServerRoute route,
  required ServerReturnType? returnType,
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

  final (:positioned, :named) = getParams(
    route.params,
    inferredParams: {
      if (route is ServerChildRoute &&
          (route.isSse || route.returnType.isStream))
        (CleanUp).name: refer('context')
            .property('data')
            .property('get')
            .call([]).ifNullThen(
          createMissingArgumentException(key: 'cleanUp', location: '@data')
              .thrown
              .parenthesized,
        ),
    },
  );
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

    if (!returnType.isStream && returnType.hasToJsonMember) {
      if (returnType.isIterable) {
        final iterates = Method(
          (p) => p
            ..requiredParameters.add(Parameter((b) => b..name = 'e'))
            ..lambda = true
            ..body = switch (returnType.isIterableNullable) {
              true => refer('e').nullSafeProperty('toJson').call([]),
              false => refer('e').property('toJson').call([]),
            }
                .code,
        ).closure;

        if (returnType.isNullable) {
          result = result.nullSafeProperty('map');
        } else {
          result = result.property('map');
        }

        result = result.call([iterates]).property('toList').call([]);
      } else if (returnType.isNullable) {
        result = result.nullSafeProperty('toJson').call([]);
      } else {
        result = result.property('toJson').call([]);
      }
    }

    setBody = refer('context').property('response').property('body');

    if (!returnType.isStream &&
        (returnType.isPrimitive ||
            returnType.hasToJsonMember ||
            returnType.isMap)) {
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
