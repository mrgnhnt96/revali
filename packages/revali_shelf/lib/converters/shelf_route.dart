import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_route_annotations.dart';

class ShelfRoute {
  const ShelfRoute({
    required this.params,
    required this.handlerName,
    required this.annotations,
  });

  factory ShelfRoute.fromMeta(MetaMethod method) {
    return ShelfRoute(
      handlerName: method.name,
      params: method.params.map(ShelfParam.fromMeta),
      annotations: ShelfRouteAnnotations.fromRoute(method),
    );
  }

  final String handlerName;
  final Iterable<ShelfParam> params;
  final ShelfRouteAnnotations annotations;
}
