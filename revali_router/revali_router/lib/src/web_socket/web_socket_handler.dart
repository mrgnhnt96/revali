import 'package:revali_router_core/web_socket/web_socket_context.dart';

typedef WebSocketCallBack = Stream<dynamic> Function(WebSocketContext);

class WebSocketHandler {
  const WebSocketHandler({
    this.onConnect,
    this.onMessage,
  }) : assert(
          onConnect != null || onMessage != null,
          'At least one of onConnect or onMessage must be provided',
        );

  final WebSocketCallBack? onConnect;
  final WebSocketCallBack? onMessage;
}
