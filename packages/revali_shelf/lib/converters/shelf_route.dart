import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_http_code.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_redirect.dart';
import 'package:revali_shelf/converters/shelf_return_type.dart';
import 'package:revali_shelf/converters/shelf_route_annotations.dart';

class ShelfRoute {
  const ShelfRoute({
    required this.params,
    required this.handlerName,
    required this.method,
    required this.path,
    required this.returnType,
    required this.annotations,
    required this.httpCode,
    required this.redirect,
  });

  factory ShelfRoute.fromMeta(MetaMethod method) {
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

    return ShelfRoute(
      handlerName: method.name,
      method: method.method,
      path: method.path ?? '',
      params: method.params.map(ShelfParam.fromMeta),
      returnType: ShelfReturnType.fromMeta(method.returnType),
      annotations: ShelfRouteAnnotations.fromRoute(method),
      httpCode: httpCode,
      redirect: redirect,
    );
  }

  final String handlerName;
  final String method;
  final String path;
  final ShelfReturnType returnType;
  final Iterable<ShelfParam> params;
  final ShelfRouteAnnotations annotations;
  final ShelfHttpCode? httpCode;
  final ShelfRedirect? redirect;
}
