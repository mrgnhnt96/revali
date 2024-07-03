import 'package:revali_router/src/request/mutable_request_context.dart';

class RequestContextImpl extends MutableRequestContext {
  RequestContextImpl(super.request);
  RequestContextImpl.from(super.request) : super.from();
}
