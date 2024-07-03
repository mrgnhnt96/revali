import 'package:revali_router/src/middleware/middleware_meta.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';

class MiddlewareContext extends MutableRequestContext {
  MiddlewareContext(
    super.request, {
    required this.meta,
  });
  MiddlewareContext.from(
    super.request, {
    required this.meta,
  }) : super.from();

  final MiddlewareMeta meta;
}
