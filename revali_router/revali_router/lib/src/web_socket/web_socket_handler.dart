class WebSocketHandler {
  const WebSocketHandler({
    this.onConnect,
    this.onMessage,
  }) : assert(
          onConnect != null || onMessage != null,
          'At least one of onConnect or onMessage must be provided',
        );

  final Stream<dynamic> Function()? onConnect;
  final Stream<dynamic> Function()? onMessage;
}
