import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/route/base_route.dart';

part 'route.g.dart';

// ignore: must_be_immutable
class Route extends BaseRoute {
  Route(
    super.path, {
    this.handler,
    super.method,
    super.routes,
    super.middlewares,
    super.requestWrappers,
    super.interceptors,
    super.guards,
    super.catchers,
    super.meta,
    super.redirect,
    super.combine,
    super.allowedOrigins,
    super.preventedHeaders,
    super.ignorePathPattern,
    super.responseHandler,
    super.expectedHeaders,
  }) : super(handler: handler);

  @override
  // ignore: overridden_fields
  final Future<void> Function(Context)? handler;

  @override
  List<Object?> get props => _$props;
}
