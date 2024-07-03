import 'package:revali_router/src/request/mutable_request_context_impl.dart';

// ignore: must_be_immutable
class EndpointContext extends MutableRequestContextImpl {
  EndpointContext(super.request);
  EndpointContext.from(super.request) : super.from();
}
