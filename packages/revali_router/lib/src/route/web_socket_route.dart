import 'dart:async';

import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/src/handler/web_socket_handler.dart';
import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'web_socket_route.g.dart';

// ignore: must_be_immutable
class WebSocketRoute extends BaseRoute {
  WebSocketRoute(
    super.path, {
    required this.mode,
    required this.handler,
    super.allowedHeaders,
    super.allowedOrigins,
    super.catchers,
    super.combine,
    super.guards,
    super.interceptors,
    super.meta,
    super.middlewares,
    super.redirect,
    super.routes,
  }) : super(
          method: 'GET',
          handler: handler,
        );

  final WebSocketMode mode;

  @override
  final FutureOr<WebSocketHandler> Function(EndpointContext) handler;

  @override
  List<Object?> get props => _$props;
}
