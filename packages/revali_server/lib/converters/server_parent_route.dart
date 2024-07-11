import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_child_route.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
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
  });

  factory ServerParentRoute.fromMeta(MetaRoute parentRoute) {
    return ServerParentRoute(
      routes: parentRoute.methods.map(ServerChildRoute.fromMeta),
      params: parentRoute.params.map(ServerParam.fromMeta),
      className: parentRoute.className,
      importPath:
          ServerImports([parentRoute.element.librarySource.uri.toString()]),
      routePath: parentRoute.path,
      annotations: ServerRouteAnnotations.fromParent(parentRoute),
    );
  }

  final String className;
  final ServerImports importPath;
  final String routePath;
  final Iterable<ServerParam> params;
  final Iterable<ServerChildRoute> routes;
  final ServerRouteAnnotations annotations;

  String get handlerName => routePath.toNoCase().toCamelCase();

  String get classVarName => className.toNoCase().toCamelCase();

  String get fileName => routePath.toNoCase().toSnakeCase();

  Iterable<ServerReflect> get reflects sync* {
    for (final route in routes) {
      yield* route.reflects;
    }

    for (final param in params) {
      yield* param.annotations.reflects;
    }
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
