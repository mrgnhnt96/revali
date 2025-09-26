import 'dart:async';

import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/src/response_handler/websocket_response_handler.dart';
import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router/src/web_socket/web_socket_handler.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'web_socket_route.g.dart';

// ignore: must_be_immutable
class WebSocketRoute extends BaseRoute {
  WebSocketRoute(
    super.path, {
    required this.mode,
    required this.handler,
    super.preventedHeaders,
    super.allowedOrigins,
    super.catchers,
    super.combine,
    super.guards,
    super.interceptors,
    super.meta,
    super.middlewares,
    super.redirect,
    this.ping,
    super.expectedHeaders,
  }) : super(
          method: 'GET',
          handler: handler,
          responseHandler: const WebsocketResponseHandler(),
        );

  final WebSocketMode mode;
  final Duration? ping;

  @override
  // ignore: overridden_fields
  final Future<WebSocketHandler> Function(Context) handler;

  @override
  List<Object?> get props => _$props;
}
