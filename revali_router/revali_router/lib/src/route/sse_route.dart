import 'package:revali_router/src/response_handler/sse_response_handler.dart';
import 'package:revali_router/src/route/base_route.dart';

part 'sse_route.g.dart';

// ignore: must_be_immutable
class SseRoute extends BaseRoute {
  SseRoute(
    super.path, {
    required super.handler,
    super.allowedHeaders,
    super.allowedOrigins,
    super.catchers,
    super.combine,
    super.guards,
    super.interceptors,
    super.meta,
    super.middlewares,
    super.redirect,
    super.responseHandler = const SseResponseHandler(),
    super.expectedHeaders,
    super.routes,
  }) : super(method: 'GET');

  @override
  List<Object?> get props => _$props;
}
