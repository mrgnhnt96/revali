import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class WebSocketContextImpl extends EndpointContextImpl
    implements WebSocketContext {
  const WebSocketContextImpl({
    required super.data,
    required super.meta,
    required super.reflect,
    required super.request,
    required super.response,
    required this.close,
    required this.asyncSender,
  });

  @override
  final CloseWebSocket close;

  @override
  final AsyncWebSocketSender<dynamic> asyncSender;
}
