import 'dart:io';

import 'package:revali_router_core/method_mutations/headers/read_only_headers.dart';
import 'package:revali_router_core/payload/payload.dart';

abstract class UnderlyingRequest {
  const UnderlyingRequest();

  Payload get body;
  ReadOnlyHeaders get headers;
  Uri get uri;
  String get method;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  String get protocolVersion;

  Future<WebSocket> upgradeToWebSocket({Duration? ping});
}
