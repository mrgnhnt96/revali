import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_http_code.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/converters/server_return_type.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerChildRoute with ExtractImport implements ServerRoute {
  ServerChildRoute({
    required this.returnType,
    required this.httpCode,
    required this.redirect,
    required this.method,
    required this.path,
    required this.annotations,
    required this.handlerName,
    required this.params,
    required this.isWebSocket,
    required this.ping,
  });

  factory ServerChildRoute.fromMeta(MetaMethod method) {
    ServerHttpCode? httpCode;
    ServerMimic? redirect;

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

            httpCode = ServerHttpCode.fromDartObject(annotation);
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

            redirect = ServerMimic.fromDartObject(annotation, source);
          },
        ),
      ],
    );

    final serverRoute = ServerRoute.fromMeta(method);

    return ServerChildRoute(
      method: method.method,
      path: method.path ?? '',
      returnType: ServerReturnType.fromMeta(method.returnType),
      httpCode: httpCode,
      redirect: redirect,
      annotations: serverRoute.annotations,
      handlerName: serverRoute.handlerName,
      params: serverRoute.params,
      isWebSocket: method.isWebSocket,
      ping: method.ping,
    );
  }

  final ServerReturnType returnType;
  final ServerHttpCode? httpCode;
  final ServerMimic? redirect;
  final String method;
  final String path;
  final bool isWebSocket;
  final Duration? ping;

  @override
  final ServerRouteAnnotations annotations;

  @override
  final String handlerName;

  @override
  final Iterable<ServerParam> params;

  Iterable<ServerReflect> get reflects sync* {
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
  List<ServerImports?> get imports => const [];
}
