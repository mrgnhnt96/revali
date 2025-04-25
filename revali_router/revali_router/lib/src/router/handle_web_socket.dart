part of 'router.dart';

class HandleWebSocket {
  HandleWebSocket({
    required dynamic handler,
    required this.mode,
    required this.ping,
    required this.helper,
  }) : _sequentialExecutor = SequentialExecutor<(int, String)?>() {
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
  final SequentialExecutor<(int, String)?> _sequentialExecutor;

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
      return await close(
        1000,
        'Normal closure, WebSocket is not open for receiving messages',
      );
    }

    if (await listenToMessages() case final WebSocketResponse response) {
      return response.toWebSocketResponse();
    }

    return await close(1000, 'Normal closure');
  }

  Future<WebSocketResponse?> listenToMessages() async {
    final HelperMixin(:debugResponses, :debugErrorResponse, :response) = helper;

    if (await _closed?.future case final response?) {
      return response;
    }

    final onMessage = handler.onMessage;
    if (onMessage == null) {
      final reason = debugResponses
          ? 'Message handler not implemented'
          : 'Internal server error';

      final response = await close(1011, reason);

      return debugErrorResponse(
        response,
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
    final HelperMixin(:debugResponses, :debugErrorResponse) = helper;

    try {
      final payload = PayloadImpl(event, encoding: wsRequest.headers.encoding);

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

      return await close(response.webSocketErrorCode, reason);
    }
  }

  Future<WebSocketResponse?> upgradeRequest() async {
    final HelperMixin(:debugErrorResponse, :request, :response) = helper;

    try {
      await request.resolvePayload();
      _webSocket = await request.upgradeToWebSocket(ping: ping);
      _wsRequest = MutableWebSocketRequestImpl.fromRequest(request, (
        code,
        reason,
      ) async {
        await close(code, reason);
      });
      helper
        ..webSocketRequest = wsRequest
        ..webSocketSender = (data) async {
          if (_closed case Object()) {
            return;
          }
          final body = MutableBodyImpl();
          await body.replace(data);

          if (await sendResponse(body) case (final code, final reason)) {
            await close(code, reason);
          }
        };

      return null;
    } catch (e, stackTrace) {
      return debugErrorResponse(
        WebSocketResponse(1007),
        error: e,
        stackTrace: stackTrace,
      ).toWebSocketResponse();
    }
  }

  Future<(int, String)?> sendResponse(BodyData bodyData) async {
    if (!mode.canSend) {
      return (1000, 'Normal closure');
    }

    Future<(int, String)?> send() async {
      final HelperMixin(:response, run: RunMixin(:interceptors)) = helper;

      sending = Completer<void>();
      void complete() {
        sending?.complete();
        sending = null;
      }

      // Not using `equatable`, so this check is if the body is the
      // same object in memory. Without this check a `StackOverflow`
      // could occur
      if (response.body != bodyData) {
        response.body = bodyData;
      }

      await interceptors.post();

      final stream = response.body.read();
      if (stream == null) {
        complete();
        return null;
      }

      try {
        await for (final chunk in stream) {
          if (webSocket
              case WebSocket(
                :final int closeCode,
                :final closeReason,
              )) {
            complete();
            return (closeCode, closeReason ?? '');
          }
          // 1 is open
          if (webSocket.readyState != 1) {
            complete();
            return (1000, 'Normal closure');
          }
          try {
            webSocket.add(chunk);
          } catch (e) {
            break;
          }
        }
      } catch (e) {
        complete();
        return (1011, 'Internal server error');
      }

      complete();

      return null;
    }

    return await _sequentialExecutor.add(send);
  }

  Future<WebSocketResponse> close(int code, String reason) async {
    _closed = Completer<WebSocketResponse>();
    await sending?.future;

    // up to 125 bytes
    final bytes = utf8.encode(reason);
    final truncated = utf8.decode(bytes.sublist(0, min(125, bytes.length)));

    await webSocket.close(code, truncated);
    if (_closed?.isCompleted case true) {
      if (await _closed?.future case final response?) {
        return response;
      } else {
        throw Exception('Expected to have a websocket response');
      }
    }

    final response = WebSocketResponse(code, body: truncated);

    _closed?.complete(response);

    return response;
  }

  Future<WebSocketResponse?> runHandler(WebSocketCallBack stream) async {
    final HelperMixin(
      run: RunMixin(:interceptors, :catchers),
      :debugErrorResponse,
      :debugResponses,
      context: ContextMixin(:webSocket),
    ) = helper;

    try {
      await interceptors.pre();

      await for (final data in stream(webSocket)) {
        final body = MutableBodyImpl();
        await body.replace(data);

        if (await sendResponse(body) case (final code, final reason)) {
          await close(code, reason);
          break;
        }
      }

      return null;
    } on CloseWebSocketException catch (e, stackTrace) {
      final response = await close(e.code, e.reason);

      return debugErrorResponse(
        response,
        stackTrace: stackTrace,
        error: e,
      ).toWebSocketResponse();
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
      headers: headers.map((key, value) => MapEntry(key, value.join(','))),
    );
  }
}
