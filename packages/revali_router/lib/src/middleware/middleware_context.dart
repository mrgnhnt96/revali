import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';

abstract class MiddlewareContext extends MutableRequestContext {
  const MiddlewareContext();

  DataHandler get data;
}
