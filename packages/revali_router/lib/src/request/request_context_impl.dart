import 'package:revali_router/src/request/mutable_request_context.dart';

// ignore: must_be_immutable
class RequestContextImpl extends MutableRequestContext {
  RequestContextImpl(super.request);
  RequestContextImpl.from(super.request) : super.from();
}
