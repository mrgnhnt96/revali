import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_child_route.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerParentRoute with ExtractImport implements ServerRoute {
  ServerParentRoute({
    required this.className,
    required this.importPath,
    required this.routePath,
    required this.routes,
    required this.params,
    required this.annotations,
    required this.index,
  });

  factory ServerParentRoute.fromMeta(MetaRoute parentRoute, int index) {
    return ServerParentRoute(
      routes: parentRoute.methods.map(ServerChildRoute.fromMeta).toList(),
      params: parentRoute.params.map(ServerParam.fromMeta).toList(),
      className: parentRoute.className,
      importPath:
          ServerImports([parentRoute.element.librarySource.uri.toString()]),
      routePath: parentRoute.path,
      annotations: ServerRouteAnnotations.fromParent(parentRoute),
      index: index,
    );
  }

  final String className;
  final ServerImports importPath;
  final String routePath;
  @override
  final List<ServerParam> params;
  final List<ServerChildRoute> routes;
  @override
  final ServerRouteAnnotations annotations;

  final int index;

  @override
  String get handlerName => '${_routeName.toCamelCase()}Route';

  String get _routeName {
    final name = routePath.toNoCase();

    if (name.isEmpty) {
      return 'r$index';
    }

    return name;
  }

  String get classVarName {
    final name = className.toNoCase().toCamelCase();

    return name;
  }

  String get fileName => '${_routeName.toSnakeCase()}_route';

  Iterable<ServerReflect> get reflects sync* {
    for (final route in routes) {
      yield* route.reflects;
    }

    for (final param in params) {
      yield* param.annotations.reflects;
    }
  }

  @override
  List<ServerPipe> get pipes {
    final pipes = <String, ServerPipe>{};

    for (final param in params) {
      for (final pipe in param.annotations.pipes) {
        pipes[pipe.clazz.className] = pipe;
      }
    }

    return pipes.values.toList();
  }

  @override
  List<ExtractImport?> get extractors => [
        ...routes,
        ...params,
        annotations,
      ];

  @override
  List<ServerImports?> get imports => [importPath];
}
