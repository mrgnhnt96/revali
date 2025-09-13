import 'dart:io';

import 'package:revali_router_core/method_mutations/headers/headers.dart';
import 'package:revali_router_core/request/underlying_request.dart';
import 'package:revali_router_core/types/types.dart';

abstract interface class RequestContext {
  const RequestContext();

  PayloadResolver? get payloadResolver;
  List<String> get segments;
  String get method;
  Headers get headers;
  Map<String, dynamic> get queryParameters;
  Map<String, Iterable<dynamic>> get queryParametersAll;
  Uri get uri;

  UnderlyingRequest get request;

  Future<WebSocket> upgradeToWebSocket({Duration? ping});

  /// Cleans up any resources used by the request
  Future<void> close();

  void addCleanUp(void Function() cleanUp);
}
