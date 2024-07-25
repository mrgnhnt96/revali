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
    required this.request,
    required this.response,
    required this.handler,
    required this.mode,
    required this.ping,
    required this.pre,
    required this.post,
    required this.debugResponse,
    required this.onCatch,
    required this.debugResponses,
  });

  final MutableRequest request;
  final MutableResponse response;
  final WebSocketHandler handler;
  final WebSocketMode mode;
  final Duration? ping;
  final Future<void> Function() pre;
  final Future<void> Function() post;
  final _DebugResponse debugResponse;
  final bool debugResponses;
  final _OnCatch onCatch;

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

  Future<ReadOnlyResponse> handle() async {
    if (await upgradeRequest() case final response?) {
      return response;
    }

    if (handler.onConnect case final onConnect?) {
      if (await runHandler(onConnect) case final response?) {
        return response;
      }
    }

    if (!mode.canReceive) {
      await close(1000, 'Normal closure');

      return SimpleResponse(
        1000,
        body: 'Normal closure, WebSocket is not open for receiving',
      );
    }

    if (await listenToMessages() case final response?) {
      return response;
    }

    await close(1000, 'Normal closure');

    return SimpleResponse(1000, body: 'Normal closure');
  }

  Future<ReadOnlyResponse?> listenToMessages() async {
    final onMessage = handler.onMessage;
    if (onMessage == null) {
      final reason = debugResponses
          ? 'Message handler not implemented'
          : 'Internal server error';

      await close(1011, reason);

      return debugResponse(
        SimpleResponse(1011),
        error: 'Message handler not implemented',
        stackTrace: StackTrace.current,
      );
    }

    await for (final event in webSocket) {
      response.body = null;

      if (await resolvePayload(event) case final response?) {
        return response;
      }

      if (await runHandler(onMessage) case final response) {
        return response;
      }
    }

    return null;
  }

  Future<ReadOnlyResponse?> resolvePayload(dynamic event) async {
    try {
      final payload = PayloadImpl.encoded(
        event,
        encoding: wsRequest.headers.encoding,
      );

      final resolved = await payload.resolve(wsRequest.headers);

      await wsRequest.overrideBody(resolved);

      return null;
    } catch (e, stackTrace) {
      final response = debugResponse(
        SimpleResponse(1007),
        stackTrace: stackTrace,
        error: e,
      );

      final reason =
          debugResponses ? e.toString() : 'Failed to resolve payload';

      await close(response.webSocketErrorCode, reason);

      return response;
    }
  }

  Future<ReadOnlyResponse?> upgradeRequest() async {
    try {
      await request.resolvePayload();
      _webSocket = await request.upgradeToWebSocket(ping: ping);
      _wsRequest = MutableWebSocketRequestImpl.fromRequest(request);

      return null;
    } catch (e, stackTrace) {
      return debugResponse(
        SimpleResponse(1007),
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

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

  Future<void> close(int code, String reason) async {
    await sending?.future;

    // up to 125 bytes
    final bytes = utf8.encode(reason);
    final truncated = utf8.decode(bytes.sublist(0, min(123, bytes.length)));

    await webSocket.close(code, truncated);
  }

  Future<ReadOnlyResponse?> runHandler(Stream<void> Function() stream) async {
    try {
      await pre();

      await for (final _ in stream()) {
        await sendResponse();
      }

      return null;
    } on CloseWebSocketException catch (e, stackTrace) {
      final response = debugResponse(
        SimpleResponse(e.code, body: e.reason),
        stackTrace: stackTrace,
        error: e,
      );

      await close(e.code, e.reason);

      return response;
    } catch (e, stackTrace) {
      final response = debugResponse(
        SimpleResponse(1011),
        error: e,
        stackTrace: stackTrace,
      );

      final reason = debugResponses ? e.toString() : 'Internal server error';

      if (e is! Exception) {
        await close(response.webSocketErrorCode, reason);

        return response;
      }

      if (await onCatch(e, stackTrace) case final response?) {
        await close(response.webSocketErrorCode, reason);

        return response;
      }

      await close(response.webSocketErrorCode, reason);

      return response;
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
}
