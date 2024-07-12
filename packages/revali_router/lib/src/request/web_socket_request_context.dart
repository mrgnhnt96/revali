import 'package:revali_router/src/request/mutable_request_context.dart';

abstract class WebSocketRequestContext implements MutableRequestContext {
  Future<void> overrideBody(Object? data);
}
