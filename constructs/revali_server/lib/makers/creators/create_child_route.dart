// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/revali_server.dart';

Spec createChildRoute(ServerChildRoute route, ServerParentRoute parent) {
  final headers = [
    ...route.annotations.setHeaders,
    ...parent.annotations.setHeaders,
  ];

  Expression? response = refer('context').property('response');
  final ogResponse = response;

  if (route.httpCode?.code case final code?) {
    response = response.cascade('statusCode').assign(literalNum(code));
  }

  for (final setHeader in headers) {
    response = response
        ?.cascade('headers')
        .index(literalString(setHeader.name))
        .assign(literalString(setHeader.value));
  }

  if (response == ogResponse) {
    response = null;
  }

  final positioned = [literalString(route.path)];

  final named = {
    ...createRouteArgs(
      route: route,
      returnType: route.returnType,
      classVarName: parent.classVarName,
      method: route.isWebSocket ? null : route.method,
      webSocket: route.webSocket,
      additionalHandlerCode: [
        if (response != null) response.statement,
      ],
    ),
    if (route.webSocket?.mode case final mode?)
      'mode': refer((WebSocketMode).name).property(mode.name),
    if (route.webSocket?.ping case final ping?)
      'ping': refer('Duration').newInstance(
        [],
        {'microseconds': literalNum(ping.inMicroseconds)},
      ),
    if (route.redirect case final redirect?)
      'redirect': literal(createMimic(redirect)),
  };

  if (route.isWebSocket) {
    return refer((WebSocketRoute).name).newInstance(positioned, named);
  }
  if (route.isSse) {
    return refer((SseRoute).name).newInstance(positioned, named);
  } else {
    return refer((Route).name).newInstance(positioned, named);
  }
}
