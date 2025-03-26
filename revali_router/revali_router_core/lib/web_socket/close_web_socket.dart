abstract interface class CloseWebSocket {
  const CloseWebSocket();

  void close([int code, String reason]);
}
