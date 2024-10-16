import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';
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
    required this.webSocket,
  });

  factory ServerChildRoute.fromMeta(MetaMethod method) {
    ServerStatusCode? httpCode;
    ServerMimic? redirect;

    method.annotationsMapper(
      onMatch: [
        OnMatch(
          classType: StatusCode,
          package: 'revali_router_annotations',
          convert: (annotation, source) {
            if (httpCode != null) {
              throw ArgumentError(
                'Only one HttpCode annotation is allowed per method',
              );
            }

            httpCode = ServerStatusCode.fromDartObject(annotation);
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
      webSocket: method.webSocketMethod,
    );
  }

  final ServerReturnType returnType;
  final ServerStatusCode? httpCode;
  final ServerMimic? redirect;
  final String method;
  final String path;
  final MetaWebSocketMethod? webSocket;

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

  bool get isWebSocket => webSocket != null;
}
