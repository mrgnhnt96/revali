import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_route_annotations.dart';

class ServerRoute {
  const ServerRoute({
    required this.params,
    required this.handlerName,
    required this.annotations,
  });

  factory ServerRoute.fromMeta(MetaMethod method) {
    return ServerRoute(
      handlerName: method.name,
      params: method.params.map(ServerParam.fromMeta),
      annotations: ServerRouteAnnotations.fromRoute(method),
    );
  }

  final String handlerName;
  final Iterable<ServerParam> params;
  final ServerRouteAnnotations annotations;
}
