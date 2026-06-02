import 'dart:io';

import 'package:revali_router_core/method_mutations/headers/headers.dart';
import 'package:revali_router_core/payload/payload.dart';
import 'package:revali_router_core/trusted_proxy/trusted_proxy.dart';

abstract class UnderlyingRequest {
  const UnderlyingRequest();

  Payload get body;
  Headers get headers;
  Uri get uri;
  String get method;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  String get protocolVersion;

  /// The IP address of the client that sent the request.
  ///
  /// Uses [TrustedProxy] headers when configured on the router; otherwise the
  /// TCP remote address.
  String? get ip;

  Future<WebSocket> upgradeToWebSocket({Duration? ping});
}
