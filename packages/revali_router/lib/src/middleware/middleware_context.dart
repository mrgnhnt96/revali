import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/response/restricted_mutable_response_context.dart';

abstract class MiddlewareContext {
  const MiddlewareContext();

  DataHandler get data;
  MutableRequestContext get request;
  RestrictedMutableResponseContext get response;
}
