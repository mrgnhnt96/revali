import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_child_route.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_reflect.dart';
import 'package:revali_shelf/converters/shelf_route.dart';
import 'package:revali_shelf/converters/shelf_route_annotations.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfParentRoute with ExtractImport implements ShelfRoute {
  ShelfParentRoute({
    required this.className,
    required this.importPath,
    required this.routePath,
    required this.routes,
    required this.params,
    required this.annotations,
  });

  factory ShelfParentRoute.fromMeta(MetaRoute parentRoute) {
    return ShelfParentRoute(
      routes: parentRoute.methods.map(ShelfChildRoute.fromMeta),
      params: parentRoute.params.map(ShelfParam.fromMeta),
      className: parentRoute.className,
      importPath:
          ShelfImports([parentRoute.element.librarySource.uri.toString()]),
      routePath: parentRoute.path,
      annotations: ShelfRouteAnnotations.fromParent(parentRoute),
    );
  }

  final String className;
  final ShelfImports importPath;
  final String routePath;
  final Iterable<ShelfParam> params;
  final Iterable<ShelfChildRoute> routes;
  final ShelfRouteAnnotations annotations;

  String get handlerName => routePath.toNoCase().toCamelCase();

  String get classVarName => className.toNoCase().toCamelCase();

  String get fileName => routePath.toNoCase().toSnakeCase();

  Iterable<ShelfReflect> get reflects sync* {
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
  List<ShelfImports?> get imports => [importPath];
}
