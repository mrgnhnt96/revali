import 'package:revali_router_core/context/base_context.dart';
import 'package:revali_router_core/reflect/reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';

abstract class EndpointContext implements BaseContext {
  const EndpointContext();

  MutableRequest get request;
  MutableResponse get response;
  ReflectHandler get reflect;
}
