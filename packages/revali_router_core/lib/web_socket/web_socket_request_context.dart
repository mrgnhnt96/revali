import 'package:revali_router_core/request/mutable_request_context.dart';

abstract class WebSocketRequestContext implements MutableRequestContext {
  Future<void> overrideBody(Object? data);
}
