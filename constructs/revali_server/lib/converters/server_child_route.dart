import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/converters/server_route.dart';
import 'package:revali_server/converters/server_route_annotations.dart';
import 'package:revali_server/converters/server_status_code.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerChildRoute with ExtractImport implements ServerRoute {
  ServerChildRoute({
    required ServerType returnType,
    required this.httpCode,
    required this.redirect,
    required this.method,
    required this.path,
    required this.annotations,
    required this.handlerName,
    required this.params,
    required this.webSocket,
    required this.isSse,
  }) : _returnType = returnType;

  factory ServerChildRoute.fromMeta(MetaMethod method) {
    ServerStatusCode? httpCode;
    ServerMimic? redirect;

    method.annotationsFor(
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
          package: 'revali_router_core',
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

    if (method.isWebSocket) {
      serverRoute.annotations.removeResponseHandler();
    }

    return ServerChildRoute(
      method: method.method,
      path: method.path ?? '',
      returnType: ServerType.fromMeta(method.returnType),
      httpCode: httpCode,
      redirect: redirect,
      annotations: serverRoute.annotations,
      handlerName: serverRoute.handlerName,
      params: serverRoute.params,
      webSocket: method.webSocketMethod,
      isSse: method.isSse,
    );
  }

  final ServerType _returnType;
  ServerType get returnType => _returnType..route = this;
  final ServerStatusCode? httpCode;
  final ServerMimic? redirect;
  final String method;
  final String path;
  final MetaWebSocketMethod? webSocket;
  final bool isSse;

  @override
  final ServerRouteAnnotations annotations;

  @override
  final String handlerName;

  @override
  final List<ServerParam> params;

  Iterable<ServerReflect> get reflects sync* {
    if (returnType.reflect case final reflect?) {
      yield reflect;
    }
  }

  bool get isWebSocket => webSocket != null;

  @override
  List<ServerPipe> get pipes {
    final pipes = <String, ServerPipe>{};

    for (final param in params) {
      for (final pipe in param.annotations.pipes) {
        pipes[pipe.clazz.className] = pipe;
      }
    }

    return pipes.values.toList();
  }

  @override
  List<ExtractImport?> get extractors => [
    redirect,
    ...params,
    annotations,
    ...reflects,
    ...pipes,
  ];

  @override
  List<ServerImports?> get imports => const [];
}
