import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_http_code.dart';
import 'package:revali_shelf/converters/shelf_imports.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_reflect.dart';
import 'package:revali_shelf/converters/shelf_return_type.dart';
import 'package:revali_shelf/converters/shelf_route.dart';
import 'package:revali_shelf/converters/shelf_route_annotations.dart';
import 'package:revali_shelf/utils/extract_import.dart';

class ShelfChildRoute with ExtractImport implements ShelfRoute {
  ShelfChildRoute({
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

  Iterable<ShelfReflect> get reflects sync* {
    if (returnType.reflect case final reflect?) {
      yield reflect;
    }
  }

  @override
  List<ExtractImport?> get extractors => [
        redirect,
        ...params,
        annotations,
      ];

  @override
  List<ShelfImports?> get imports => const [];
}
