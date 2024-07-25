part of 'router.dart';

typedef _DebugResponse = ReadOnlyResponse Function(
  ReadOnlyResponse response, {
  required Object error,
  required StackTrace stackTrace,
});

typedef _OnCatch = Future<ReadOnlyResponse?> Function(
  Exception e,
  StackTrace stackTrace,
);

class _HandleWebSocket {
  _HandleWebSocket({
    required this.handler,
    required this.mode,
    required this.ping,
    required this.helper,
  });

  final WebSocketHandler handler;
  final WebSocketMode mode;
  final Duration? ping;
  final RouterHelperMixin helper;

  Completer<void>? sending;

  MutableWebSocketRequest? _wsRequest;
  MutableWebSocketRequest get wsRequest {
    final wsRequest = _wsRequest;

    if (wsRequest == null) {
      throw StateError('WebSocket request is not available');
    }

    return wsRequest;
  }

  WebSocket? _webSocket;
  WebSocket get webSocket {
    final webSocket = _webSocket;

    if (webSocket == null) {
      throw StateError('WebSocket is not available');
    }

    return webSocket;
  }

  Future<WebSocketResponse> handle() async {
    if (await upgradeRequest() case final response?) {
      return response.toWebSocketResponse();
    }

    if (handler.onConnect case final onConnect?) {
      if (await runHandler(onConnect) case final response?) {
        return response.toWebSocketResponse();
      }
    }

    if (!mode.canReceive) {
      await close(1000, 'Normal closure');

      return WebSocketResponse(
        1000,
        body: 'Normal closure, WebSocket is not open for receiving',
      );
    }

    if (await listenToMessages() case final response?) {
      return response.toWebSocketResponse();
    }

    await close(1000, 'Normal closure');

    return WebSocketResponse(1000, body: 'Normal closure');
  }

  Future<WebSocketResponse?> listenToMessages() async {
    final RouterHelperMixin(
      :debugResponses,
      :debugErrorResponse,
      :response,
    ) = helper;

    final onMessage = handler.onMessage;
    if (onMessage == null) {
      final reason = debugResponses
          ? 'Message handler not implemented'
          : 'Internal server error';

      await close(1011, reason);

      return debugErrorResponse(
        WebSocketResponse(1011),
        error: 'Message handler not implemented',
        stackTrace: StackTrace.current,
      ).toWebSocketResponse();
    }

    await for (final event in webSocket) {
      response.body = null;

      if (await resolvePayload(event) case final response?) {
        return response.toWebSocketResponse();
      }

      if (await runHandler(onMessage) case final response) {
        return response;
      }
    }

    return null;
  }

  Future<WebSocketResponse?> resolvePayload(dynamic event) async {
    final RouterHelperMixin(
      :debugResponses,
      :debugErrorResponse,
    ) = helper;

    try {
      final payload = PayloadImpl.encoded(
        event,
        encoding: wsRequest.headers.encoding,
      );

      final resolved = await payload.resolve(wsRequest.headers);

      await wsRequest.overrideBody(resolved);

      return null;
    } catch (e, stackTrace) {
      final response = debugErrorResponse(
        WebSocketResponse(1007),
        stackTrace: stackTrace,
        error: e,
      );

      final reason =
          debugResponses ? e.toString() : 'Failed to resolve payload';

      await close(response.webSocketErrorCode, reason);

      return response.toWebSocketResponse();
    }
  }

  Future<WebSocketResponse?> upgradeRequest() async {
    final RouterHelperMixin(
      :debugErrorResponse,
      :request,
    ) = helper;

    try {
      await request.resolvePayload();
      _webSocket = await request.upgradeToWebSocket(ping: ping);
      _wsRequest = MutableWebSocketRequestImpl.fromRequest(request);

      return null;
    } catch (e, stackTrace) {
      return debugErrorResponse(
        WebSocketResponse(1007),
        error: e,
        stackTrace: stackTrace,
      ).toWebSocketResponse();
    }
  }

  Future<void> sendResponse() async {
    if (!mode.canSend) {
      return;
    }

    final RouterHelperMixin(
      :response,
      :runInterceptors,
    ) = helper;

    sending = Completer<void>();

    await runInterceptors.post();

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

  Future<void> close(int code, String reason) async {
    await sending?.future;

    // up to 125 bytes
    final bytes = utf8.encode(reason);
    final truncated = utf8.decode(bytes.sublist(0, min(123, bytes.length)));

    await webSocket.close(code, truncated);
  }

  Future<WebSocketResponse?> runHandler(Stream<void> Function() stream) async {
    final RouterHelperMixin(
      :runInterceptors,
      :debugErrorResponse,
      :debugResponses,
      :runCatchers,
    ) = helper;

    try {
      await runInterceptors.pre();

      await for (final _ in stream()) {
        await sendResponse();
      }

      return null;
    } on CloseWebSocketException catch (e, stackTrace) {
      final response = debugErrorResponse(
        WebSocketResponse(e.code, body: e.reason),
        stackTrace: stackTrace,
        error: e,
      );

      await close(e.code, e.reason);

      return response.toWebSocketResponse();
    } catch (e, stackTrace) {
      final response = await runCatchers(
        e,
        stackTrace,
        defaultResponse: WebSocketResponse(1011),
      );

      await close(
        response.webSocketErrorCode,
        debugResponses ? '$e' : 'Internal server error',
      );

      return response.toWebSocketResponse();
    }
  }
}

extension _ResponseX on ReadOnlyResponse {
  int get webSocketErrorCode {
    if (statusCode < 1000) {
      return 1007;
    }

    return statusCode;
  }

  WebSocketResponse toWebSocketResponse() {
    return WebSocketResponse(
      statusCode,
      body: body,
      headers: headers.map(
        (key, value) => MapEntry(key, value.join(',')),
      ),
    );
  }
}
