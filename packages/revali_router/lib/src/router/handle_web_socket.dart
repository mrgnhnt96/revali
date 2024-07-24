part of 'router.dart';

extension HandleWebSocket on Router {
  Future<ReadOnlyResponse> handleWebsocket({
    required MutableRequest request,
    required MutableResponse response,
    required WebSocketHandler handler,
    required WebSocketMode mode,
    required Duration? ping,
    required Future<void> Function() pre,
    required Future<void> Function() post,
  }) async {
    WebSocket webSocket;
    MutableWebSocketRequest wsRequest;
    try {
      await request.resolvePayload();
      webSocket = await request.upgradeToWebSocket(ping: ping);
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

      await for (final chunk in stream) {
        webSocket.add(chunk);
      }

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

    Future<void> close(int code, String reason) async {
      await handlerSub?.cancel();
      await webSocketSub?.cancel();
      await sending?.future;

      await webSocket.close(code, reason);
    }

    webSocketSub = !mode.canReceive
        ? null
        : webSocket.listen(
            (event) async {
              response.body = null;

              try {
                final payload = PayloadImpl.encoded(
                  event,
                  encoding: wsRequest.headers.encoding,
                );

                final resolved = await payload.resolve(wsRequest.headers);

                await wsRequest.overrideBody(resolved);
              } catch (e, stackTrace) {
                final response = _debugResponse(
                  defaultResponses.internalServerError,
                  stackTrace: stackTrace,
                  error: e,
                );

                var phrase = '';

                if (response.body case final body? when !body.isNull) {
                  final stream = body.read();

                  if (stream != null) {
                    await for (final chunk in stream) {
                      phrase += utf8.decode(chunk);
                    }
                  }
                }

                if (phrase.isEmpty) {
                  phrase = 'Failed to resolve payload';
                }

                final code =
                    response.statusCode < 1000 ? 1007 : response.statusCode;

                await close(code, phrase);
                return;
              }

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
    await close(1000, 'Normal closure');

    return CannedResponse.webSocket();
  }
}
