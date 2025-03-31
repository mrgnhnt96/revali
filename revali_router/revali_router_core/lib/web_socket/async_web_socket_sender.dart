abstract interface class AsyncWebSocketSender<T> {
  const AsyncWebSocketSender();

  void send(T data);
}
