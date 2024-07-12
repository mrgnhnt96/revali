import 'dart:io';

import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';
import 'package:revali_router/src/request/parts/underlying_request.dart';
import 'package:revali_router/src/request/web_socket_request_context.dart';

abstract class RequestContext {
  const RequestContext();

  String get payload;
  ReadOnlyBody get body;
  List<String> get segments;
  String get method;
  ReadOnlyHeaders get headers;
  Map<String, String> get queryParameters;
  Map<String, List<String>> get queryParametersAll;
  Uri get uri;

  UnderlyingRequest get request;

  Future<(WebSocket, WebSocketRequestContext)> upgradeToWebSocket(
      {Duration? ping});
}
