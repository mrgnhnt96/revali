import 'dart:io';

import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';
import 'package:revali_router/src/request/parts/payload.dart';

class UnderlyingRequest {
  const UnderlyingRequest({
    required this.body,
    required this.headers,
    required this.uri,
    required this.method,
    required HttpRequest request,
    required this.protocolVersion,
  }) : _request = request;

  factory UnderlyingRequest.fromRequest(HttpRequest request) {
    final headers = MutableHeadersImpl.from(request.headers);

    return UnderlyingRequest(
      body: Payload(request),
      headers: headers,
      uri: request.uri,
      method: request.method,
      request: request,
      protocolVersion: request.protocolVersion,
    );
  }

  final Payload body;
  final ReadOnlyHeaders headers;
  final Uri uri;
  final String method;
  final HttpRequest _request;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  final String protocolVersion;

  Future<WebSocket> upgradeToWebSocket({Duration? ping}) async {
    final webSocket = await WebSocketTransformer.upgrade(_request);
    if (ping != null) {
      webSocket.pingInterval = ping;
    }

    return webSocket;
  }
}
