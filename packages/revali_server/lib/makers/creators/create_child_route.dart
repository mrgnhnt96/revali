import 'package:code_builder/code_builder.dart';
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

  if ('$response' == '$ogResponse') {
    response = null;
  }

  final positioned = [literalString(route.path)];

  final named = {
    ...createRouteArgs(
      route: route,
      returnType: route.returnType,
      classVarName: parent.classVarName,
      method: route.isWebSocket ? null : route.method,
      statusCode: route.httpCode?.code,
      additionalHandlerCode: [
        if (response != null) response.statement,
      ],
    ),
    if (route.ping case final ping? when route.isWebSocket)
      'ping': refer('Duration').newInstance(
        [],
        {'microseconds': literalNum(ping.inMicroseconds)},
      ),
    if (route.redirect case final redirect?)
      'redirect': literal(createMimic(redirect)),
  };

  if (route.isWebSocket) {
    return refer('Route').newInstanceNamed('webSocket', positioned, named);
  } else {
    return refer('Route').newInstance(positioned, named);
  }
}
