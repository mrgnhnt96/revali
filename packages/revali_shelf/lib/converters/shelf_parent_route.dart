import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfParentRoute {
  const ShelfParentRoute({
    required this.className,
    required this.filePath,
    required this.routePath,
    required this.routes,
    required this.params,
    required this.annotations,
  });

  factory ShelfParentRoute.fromMeta(MetaRoute parentRoute) {
    return ShelfParentRoute(
      routes: parentRoute.methods.map(ShelfRoute.fromMeta),
      params: parentRoute.params.map(ShelfParam.fromMeta),
      className: parentRoute.className,
      filePath: parentRoute.filePath,
      routePath: parentRoute.path,
      annotations: ShelfRouteAnnotations.fromParent(parentRoute),
    );
  }

  final String className;
  final String filePath;
  final String routePath;
  final Iterable<ShelfParam> params;
  final Iterable<ShelfRoute> routes;
  final ShelfRouteAnnotations annotations;

  String get handlerName => routePath.toNoCase().toCamelCase();

  String get classVarName => className.toNoCase().toCamelCase();

  String get fileName => routePath.toNoCase().toSnakeCase();
}
