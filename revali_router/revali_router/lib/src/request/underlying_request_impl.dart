import 'dart:io';

import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router/src/payload/payload_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class UnderlyingRequestImpl implements UnderlyingRequest {
  const UnderlyingRequestImpl({
    required this.body,
    required this.headers,
    required this.uri,
    required this.method,
    required HttpRequest request,
    required this.protocolVersion,
  }) : _request = request;

  factory UnderlyingRequestImpl.fromRequest(HttpRequest request) {
    final headers = HeadersImpl.from(request.headers);

    return UnderlyingRequestImpl(
      body: PayloadImpl(
        request,
        encoding: headers.encoding,
      ),
      headers: headers,
      uri: request.uri,
      method: request.method,
      request: request,
      protocolVersion: request.protocolVersion,
    );
  }

  @override
  final Payload body;
  @override
  final Headers headers;
  @override
  final Uri uri;
  @override
  final String method;
  final HttpRequest _request;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  @override
  final String protocolVersion;

  @override
  Future<WebSocket> upgradeToWebSocket({Duration? ping}) async {
    final webSocket = await WebSocketTransformer.upgrade(_request);
    if (ping != null) {
      webSocket.pingInterval = ping;
    }

    return webSocket;
  }

  String get originalPayload => body.readAsString();
}
