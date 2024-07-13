import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/request/mutable_request_context.dart';
import 'package:revali_router_core/response/restricted_mutable_response_context.dart';

abstract class MiddlewareContext {
  const MiddlewareContext();

  DataHandler get data;
  MutableRequestContext get request;
  RestrictedMutableResponseContext get response;
}
