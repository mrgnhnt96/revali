import 'package:revali_router/src/request/mutable_request_context.dart';

class EndpointContext extends MutableRequestContext {
  EndpointContext(super.request);
  EndpointContext.from(super.request) : super.from();
}
