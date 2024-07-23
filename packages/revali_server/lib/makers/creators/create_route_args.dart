import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_return_type.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/makers/creators/create_handler.dart';
import 'package:revali_server/makers/creators/create_modifier_args.dart';

Map<String, Expression> createRouteArgs({
  required ServerRoute route,
  ServerReturnType? returnType,
  String? classVarName,
  String? method,
  int? statusCode,
  MetaWebSocketMethod? webSocket,
  List<Code> additionalHandlerCode = const [],
}) {
  return {
    ...createModifierArgs(annotations: route.annotations),
    if (method != null) 'method': literalString(method),
    if (createHandler(
      route: route,
      returnType: returnType,
      classVarName: classVarName,
      webSocket: webSocket,
    )
        case final handler?)
      'handler': handler,
  };
}
