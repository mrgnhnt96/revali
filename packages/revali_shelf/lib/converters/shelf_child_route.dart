import 'package:revali_construct/models/meta_method.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_http_code.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_redirect.dart';
import 'package:revali_shelf/converters/shelf_return_type.dart';
import 'package:revali_shelf/converters/shelf_route.dart';
import 'package:revali_shelf/converters/shelf_route_annotations.dart';

class ShelfChildRoute implements ShelfRoute {
  const ShelfChildRoute({
    required this.returnType,
    required this.httpCode,
    required this.redirect,
    required this.method,
    required this.path,
    required this.annotations,
    required this.handlerName,
    required this.params,
  });

  factory ShelfChildRoute.fromMeta(MetaMethod method) {
    ShelfHttpCode? httpCode;
    if (method.annotationsFor(
      classType: HttpCode,
      package: 'revali_router_annotations',
    )
        case final annotations when annotations.isNotEmpty) {
      if (annotations.length > 1) {
        throw ArgumentError(
          'Only one HttpCode annotation is allowed per method',
        );
      }

      httpCode = ShelfHttpCode.fromDartObject(annotations.first);
    }

    ShelfRedirect? redirect;
    if (method.annotationsFor(
      classType: Redirect,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      if (annotations.length > 1) {
        throw ArgumentError(
          'Only one Redirect annotation is allowed per method',
        );
      }

      redirect = ShelfRedirect.fromDartObject(annotations.first);
    }

    final shelfRoute = ShelfRoute.fromMeta(method);

    return ShelfChildRoute(
      method: method.method,
      path: method.path ?? '',
      returnType: ShelfReturnType.fromMeta(method.returnType),
      httpCode: httpCode,
      redirect: redirect,
      annotations: shelfRoute.annotations,
      handlerName: shelfRoute.handlerName,
      params: shelfRoute.params,
    );
  }

  final ShelfReturnType returnType;
  final ShelfHttpCode? httpCode;
  final ShelfRedirect? redirect;
  final String method;
  final String path;

  @override
  final ShelfRouteAnnotations annotations;

  @override
  final String handlerName;

  @override
  final Iterable<ShelfParam> params;
}
