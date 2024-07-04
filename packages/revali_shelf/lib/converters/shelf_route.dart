import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_route_annotations.dart';
import 'package:revali_shelf/converters/shelf_return_type.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfRoute {
  const ShelfRoute({
    required this.params,
    required this.handlerName,
    required this.method,
    required this.path,
    required this.returnType,
    required this.annotations,
  });

  factory ShelfRoute.fromMeta(MetaMethod method) {
    return ShelfRoute(
      handlerName: method.name,
      method: method.method,
      path: method.path ?? '',
      params: method.params.map(ShelfParam.fromMeta),
      returnType: ShelfReturnType.fromMeta(method.returnType),
      annotations: ShelfRouteAnnotations.fromRoute(method),
    );
  }

  final String handlerName;
  final String method;
  final String path;
  final ShelfReturnType returnType;
  final Iterable<ShelfParam> params;
  final ShelfRouteAnnotations annotations;
}
