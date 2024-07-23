class WebSocketHandler {
  const WebSocketHandler({
    required this.onMessage,
  });

  final Stream<dynamic> Function() onMessage;
}
