import 'package:revali_core/revali_core.dart';

class AsyncWebSocketSenderImpl<T> implements AsyncWebSocketSender<T> {
  const AsyncWebSocketSenderImpl(this._sender);

  final void Function(T data) _sender;

  @override
  void send(T data) => _sender(data);
}
