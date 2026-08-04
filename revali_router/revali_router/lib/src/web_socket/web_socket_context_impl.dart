import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/context/context_impl.dart';

class WebSocketContextImpl extends ContextImpl implements WebSocketContext {
  const WebSocketContextImpl({
    required super.data,
    required super.meta,
    required super.reflect,
    required super.request,
    required super.response,
    required super.route,
    required this.close,
    required this.asyncSender,
  });

  @override
  final CloseWebSocket close;

  @override
  final AsyncWebSocketSender<dynamic> asyncSender;
}
