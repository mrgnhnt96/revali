import 'package:revali_router/src/middleware/middleware_context.dart';

class MiddlewareContextImpl extends MiddlewareContext {
  MiddlewareContextImpl(
    super.request, {
    required super.meta,
  });
  MiddlewareContextImpl.from(
    super.request, {
    required super.meta,
  }) : super.from();
}
