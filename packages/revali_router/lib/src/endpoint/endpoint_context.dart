import 'package:revali_router/src/request/mutable_request_context.dart';

// ignore: must_be_immutable
class EndpointContext extends MutableRequestContext {
  EndpointContext(super.request);
  EndpointContext.from(super.request) : super.from();
}
