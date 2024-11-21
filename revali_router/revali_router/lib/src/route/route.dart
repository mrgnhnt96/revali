import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'route.g.dart';

// ignore: must_be_immutable
class Route extends BaseRoute {
  Route(
    super.path, {
    this.handler,
    super.method,
    super.routes,
    super.middlewares,
    super.interceptors,
    super.guards,
    super.catchers,
    super.meta,
    super.redirect,
    super.combine,
    super.allowedOrigins,
    super.allowedHeaders,
    super.ignorePathPattern,
    super.responseHandler,
    super.expectedHeaders,
  }) : super(handler: handler);

  @override
  // ignore: overridden_fields
  final Future<void> Function(EndpointContext)? handler;

  @override
  List<Object?> get props => _$props;
}
