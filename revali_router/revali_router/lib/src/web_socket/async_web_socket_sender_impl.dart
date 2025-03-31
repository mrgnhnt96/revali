import 'package:revali_router_core/revali_router_core.dart';

class AsyncWebSocketSenderImpl<T> implements AsyncWebSocketSender<T> {
  const AsyncWebSocketSenderImpl(this._sender);

  final void Function(T data) _sender;

  @override
  void send(T data) => _sender(data);
}
