import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfParentRoute implements ShelfRoute {
  const ShelfParentRoute({
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

  Iterable<String> get imports sync* {
    yield* importPath.imports;
    for (final route in routes) {
      yield* route.imports;
    }

    for (final param in params) {
      if (param.importPath case final importPath?) {
        yield* importPath.imports;
      }
    }

    yield* annotations.imports;
  }
}
