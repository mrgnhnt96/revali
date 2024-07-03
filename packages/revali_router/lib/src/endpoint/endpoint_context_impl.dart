import 'package:revali_router/src/endpoint/endpoint_context.dart';

class EndpointContextImpl extends EndpointContext {
  EndpointContextImpl(super.request);
  EndpointContextImpl.from(super.request) : super.from();
}
