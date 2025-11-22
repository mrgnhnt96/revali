import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_pipe.dart';
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
      params: method.params.map(ServerParam.fromMeta).toList(),
      annotations: ServerRouteAnnotations.fromRoute(method),
    );
  }

  final String handlerName;
  final List<ServerParam> params;
  final ServerRouteAnnotations annotations;

  @override
  List<ExtractImport?> get extractors => [...params, annotations];

  @override
  List<ServerImports?> get imports => [];

  List<ServerPipe> get pipes {
    final pipes = <String, ServerPipe>{};

    for (final param in params) {
      for (final pipe in param.annotations.pipes) {
        pipes[pipe.clazz.className] = pipe;
      }
    }

    return pipes.values.toList();
  }
}
