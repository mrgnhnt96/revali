import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class MiddlewareContext {
  const MiddlewareContext();

  DataHandler get data;
  MutableRequest get request;
  RestrictedMutableResponse get response;
}
