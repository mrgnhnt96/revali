import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerRoute with ExtractImport {
  ServerRoute({
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

  @override
  List<ExtractImport?> get extractors => [
        ...params,
        annotations,
      ];

  @override
  List<ServerImports?> get imports => [];
}
