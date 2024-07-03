import 'package:revali_router/src/middleware/middleware_context.dart';
import 'package:revali_router/src/request/mutable_request_context_impl.dart';

// ignore: must_be_immutable
class MiddlewareContextImpl extends MutableRequestContextImpl
    implements MiddlewareContext {
  MiddlewareContextImpl(super.request);
  MiddlewareContextImpl.from(super.request) : super.from();
}
