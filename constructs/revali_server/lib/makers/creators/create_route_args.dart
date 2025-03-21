import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/create_handler.dart';
import 'package:revali_server/makers/creators/create_modifier_args.dart';

Map<String, Expression> createRouteArgs({
  required ServerRoute route,
  ServerType? returnType,
  String? classVarName,
  String? method,
  MetaWebSocketMethod? webSocket,
  List<Code> additionalHandlerCode = const [],
}) {
  return {
    ...createModifierArgs(annotations: route.annotations),
    if (method != null) 'method': literalString(method),
    if ((returnType, classVarName)
        case (final returnType?, final classVarName?))
      if (createHandler(
        route: route,
        returnType: returnType,
        classVarName: classVarName,
        webSocket: webSocket,
        additionalHandlerCode: additionalHandlerCode,
      )
          case final handler)
        'handler': handler,
  };
}
