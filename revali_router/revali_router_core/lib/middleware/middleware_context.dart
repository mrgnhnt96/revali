import 'package:revali_router_core/context/base_context.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class MiddlewareContext implements BaseContext {
  const MiddlewareContext();

  MutableRequest get request;
  RestrictedMutableResponse get response;
}
