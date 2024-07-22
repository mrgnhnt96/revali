part of 'router.dart';

extension HandleWebSocket on Router {
  Future<ReadOnlyResponse> handleWebsocket({
    required MutableRequest request,
    required MutableResponse response,
    required Future<void> Function() run,
  }) async {
    WebSocket webSocket;
    MutableWebSocketRequest wsRequest;
    try {
      webSocket = await request.upgradeToWebSocket();
      wsRequest = MutableWebSocketRequestImpl.fromRequest(request);
    } catch (e, stackTrace) {
      return _debugResponse(
        defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );
    }

    final sub = webSocket.listen((event) async {
      response.body = null;
      await wsRequest.overrideBody(event);

      await run();

      final body = response.body;
      if (body.isNull) {
        return;
      }

      webSocket.add(body.read());
    });

    await sub.asFuture();

    return CannedResponse.webSocket();
  }
}
