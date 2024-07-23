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

    Completer<void>? sending;

    Future<void> sendResponse() async {
      if (!mode.canSend) {
        return;
      }

      sending = Completer<void>();

      await post();

      final body = response.body;
      if (body.isNull) {
        sending?.complete();
        return;
      }

      final stream = body.read();
      if (stream == null) {
        sending?.complete();
        return;
      }

      final bytes = (await stream.toList()).expand((e) => e).toList();
      webSocket.add(bytes);
      sending?.complete();
    }

    StreamSubscription? handlerSub;
    await pre();
    handlerSub = handler.onConnect?.call().listen(
      (_) async {
        await sendResponse();
      },
    );

    StreamSubscription? webSocketSub;
    webSocketSub = !mode.canReceive
        ? null
        : webSocket.listen(
            (event) async {
              response.body = null;
              print('event: $event');
              await wsRequest.overrideBody(event);

              await pre();

              await handlerSub?.cancel();
              handlerSub = handler.onMessage?.call().listen(
                (_) async {
                  await sendResponse();
                },
              );
            },
          );

    await webSocketSub?.asFuture();
    await handlerSub?.asFuture();
    await handlerSub?.cancel();
    await webSocketSub?.cancel();
    await sending?.future;
    await webSocket.close();

    return CannedResponse.webSocket();
  }
}
