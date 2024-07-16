import 'dart:io';

import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/request/underlying_request.dart';
import 'package:revali_router_core/utils/types.dart';

abstract class RequestContext {
  const RequestContext();

  PayloadResolver? get payloadResolver;
  List<String> get segments;
  String get method;
  ReadOnlyHeaders get headers;
  Map<String, String> get queryParameters;
  Map<String, List<String>> get queryParametersAll;
  Uri get uri;

  UnderlyingRequest get request;

  Future<WebSocket> upgradeToWebSocket({Duration? ping});
}