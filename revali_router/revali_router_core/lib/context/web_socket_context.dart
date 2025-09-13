import 'package:revali_router_core/context/context.dart';
import 'package:revali_router_core/web_socket/async_web_socket_sender.dart';
import 'package:revali_router_core/web_socket/close_web_socket.dart';

abstract interface class WebSocketContext implements Context {
  const WebSocketContext();

  CloseWebSocket get close;

  AsyncWebSocketSender<dynamic> get asyncSender;
}
