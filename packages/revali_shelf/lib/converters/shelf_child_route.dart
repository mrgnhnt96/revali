import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_http_code.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
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
    ShelfMimic? redirect;

    method.annotationsMapper(
      onMatch: [
        OnMatch(
          classType: HttpCode,
          package: 'revali_router_annotations',
          convert: (annotation, source) {
            if (httpCode != null) {
              throw ArgumentError(
                'Only one HttpCode annotation is allowed per method',
              );
            }

            httpCode = ShelfHttpCode.fromDartObject(annotation);
          },
        ),
        OnMatch(
          classType: Redirect,
          package: 'revali_router',
          convert: (annotation, source) {
            if (redirect != null) {
              throw ArgumentError(
                'Only one Redirect annotation is allowed per method',
              );
            }

            redirect = ShelfMimic.fromDartObject(annotation, source);
          },
        ),
      ],
    );

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
  final ShelfMimic? redirect;
  final String method;
  final String path;

  @override
  final ShelfRouteAnnotations annotations;

  @override
  final String handlerName;

  @override
  final Iterable<ShelfParam> params;

  Iterable<String> get imports sync* {
    if (redirect case final redirect?) {
      yield* redirect.imports.imports;
    }

    yield* annotations.imports;

    for (final param in params) {
      yield* param.imports;
    }
  }
}
