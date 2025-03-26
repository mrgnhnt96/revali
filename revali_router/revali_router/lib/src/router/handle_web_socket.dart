part of 'router.dart';

class HandleWebSocket {
  HandleWebSocket({
    required dynamic handler,
    required this.mode,
    required this.ping,
    required this.helper,
  }) {
    if (handler is! WebSocketHandler) {
      throw InvalidHandlerResultException('${handler.runtimeType}', [
        '$WebSocketHandler',
        'Future<$WebSocketHandler>',
      ]);
    }

    // ignore: prefer_initializing_formals
    this.handler = handler;
  }

  late final WebSocketHandler handler;
  final WebSocketMode mode;
  final Duration? ping;
  final HelperMixin helper;

  Completer<WebSocketResponse>? _closed;

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

  Future<WebSocketResponse> execute() async {
    if (await upgradeRequest() case final WebSocketResponse response) {
      return response.toWebSocketResponse();
    }

    if (handler.onConnect case final WebSocketCallBack onConnect) {
      if (await runHandler(onConnect) case final WebSocketResponse response) {
        return response.toWebSocketResponse();
      }
    }

    if (!mode.canReceive) {
      await close(1000, 'Normal closure');

      return WebSocketResponse(
        1000,
        body: 'Normal closure, WebSocket is not open for receiving messages',
      );
    }

    if (await listenToMessages() case final WebSocketResponse response) {
      return response.toWebSocketResponse();
    }

    await close(1000, 'Normal closure');

    return WebSocketResponse(1000, body: 'Normal closure');
  }

  Future<WebSocketResponse?> listenToMessages() async {
    final HelperMixin(
      :debugResponses,
      :debugErrorResponse,
      :response,
    ) = helper;

    if (await _closed?.future case final response?) {
      return response;
    }

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

      if (await resolvePayload(event) case final WebSocketResponse response) {
        return response.toWebSocketResponse();
      }

      if (await runHandler(onMessage) case final WebSocketResponse response) {
        return response;
      }
    }

    return null;
  }

  Future<WebSocketResponse?> resolvePayload(dynamic event) async {
    final HelperMixin(
      :debugResponses,
      :debugErrorResponse,
    ) = helper;

    try {
      final payload = PayloadImpl.encoded(
        event,
        encoding: wsRequest.headers.encoding,
      );

      final resolved = await payload.coerce(wsRequest.headers);

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
    final HelperMixin(
      :debugErrorResponse,
      :request,
    ) = helper;

    try {
      await request.resolvePayload();
      _webSocket = await request.upgradeToWebSocket(ping: ping);
      _wsRequest = MutableWebSocketRequestImpl.fromRequest(
        request,
        (code, reason) async {
          await sendResponse();
          await close(code, reason);
        },
      );
      helper.webSocketRequest = wsRequest;

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
    if (sending != null) {
      return;
    }

    final HelperMixin(
      :response,
      run: RunMixin(
        :interceptors,
      )
    ) = helper;

    sending = Completer<void>();

    await interceptors.post();

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
    _closed = Completer<WebSocketResponse>();
    await sending?.future;

    // up to 125 bytes
    final bytes = utf8.encode(reason);
    final truncated = utf8.decode(bytes.sublist(0, min(125, bytes.length)));

    await webSocket.close(code, truncated);

    _closed?.complete(WebSocketResponse(code, body: truncated));
  }

  Future<WebSocketResponse?> runHandler(WebSocketCallBack stream) async {
    final HelperMixin(
      run: RunMixin(
        :interceptors,
        :catchers,
      ),
      :debugErrorResponse,
      :debugResponses,
      context: ContextMixin(
        :webSocket,
      )
    ) = helper;

    try {
      await interceptors.pre();

      await for (final _ in stream(webSocket)) {
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
      final response = await catchers(
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
