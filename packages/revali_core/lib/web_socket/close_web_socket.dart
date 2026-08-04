abstract interface class CloseWebSocket {
  const CloseWebSocket();

  void call([int code, String reason]);

  void close([int code, String reason]);
}
