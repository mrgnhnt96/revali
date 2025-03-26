import 'package:revali_router_core/endpoint/endpoint_context.dart';
import 'package:revali_router_core/web_socket/close_web_socket.dart';

abstract interface class WebSocketContext implements EndpointContext {
  const WebSocketContext();

  CloseWebSocket get close;
}
