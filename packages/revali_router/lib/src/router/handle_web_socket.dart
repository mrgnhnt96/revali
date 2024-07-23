part of 'router.dart';

extension HandleWebSocket on Router {
  Future<ReadOnlyResponse> handleWebsocket({
    required MutableRequest request,
    required MutableResponse response,
    required WebSocketHandler handler,
    required WebSocketMode mode,
    required Future<void> Function() pre,
    required Future<void> Function() post,
  }) async {
    WebSocket webSocket;
    MutableWebSocketRequest wsRequest;
    try {
      await request.resolvePayload();
      webSocket = await request.upgradeToWebSocket();
      wsRequest = MutableWebSocketRequestImpl.fromRequest(request);
    } catch (e, stackTrace) {
      return _debugResponse(
        defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );
    }

    StreamSubscription? webSocketSub;
    StreamSubscription? handlerSub;
    webSocketSub = webSocket.listen(
      (event) async {
        response.body = null;
        await wsRequest.overrideBody(event);

        await pre();

        await handlerSub?.cancel();
        handlerSub = handler.onMessage().listen(
          (newBody) async {
            await post();

            final body = response.body;
            if (body.isNull) {
              return;
            }

            final stream = body.read();
            if (stream == null) {
              return;
            }

            final bytes = (await stream.toList()).expand((e) => e).toList();
            webSocket.add(bytes);
          },
          onDone: () async {
            await handlerSub?.cancel();
          },
          onError: (e, stackTrace) async {
            await handlerSub?.cancel();
          },
        );
      },
      onDone: () async {
        await handlerSub?.cancel();
        await webSocketSub?.cancel();
      },
      onError: (e, stackTrace) async {
        await webSocketSub?.cancel();
        await handlerSub?.cancel();
      },
    );

    await webSocketSub.asFuture();
    await handlerSub?.cancel();
    await webSocketSub.cancel();

    return CannedResponse.webSocket();
  }
}
