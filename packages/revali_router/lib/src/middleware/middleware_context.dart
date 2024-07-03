import 'package:revali_router/src/request/mutable_request_context.dart';

// ignore: must_be_immutable
class MiddlewareContext extends MutableRequestContext {
  MiddlewareContext(super.request);
  MiddlewareContext.from(super.request) : super.from();
}
