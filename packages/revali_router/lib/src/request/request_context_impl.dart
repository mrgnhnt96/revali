import 'dart:io';

import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';
import 'package:revali_router/src/request/parts/underlying_request.dart';
import 'package:revali_router/src/request/web_socket_request_context.dart';
import 'package:revali_router/src/request/websocket_request_context_impl.dart';

part 'request_context_impl.g.dart';

class RequestContextImpl with EquatableMixin implements RequestContext {
  RequestContextImpl(
    this.request, {
    required String payload,
  })  : _payload = payload,
        _payloadResolver = null;

  RequestContextImpl._noPayload(
    this.request, {
    required Future<String> Function() payloadResolver,
  }) : _payloadResolver = payloadResolver;

  factory RequestContextImpl.fromRequest(HttpRequest httpRequest) {
    final request = UnderlyingRequest.fromRequest(httpRequest);

    return RequestContextImpl._noPayload(
      request,
      payloadResolver: request.body.readAsString,
    );
  }

  RequestContextImpl.self(RequestContext context)
      : request = context.request,
        _payload = context.payload,
        _payloadResolver = null;

  RequestContextImpl.base(RequestContext context, HttpRequest httpRequest)
      : request = UnderlyingRequest.fromRequest(httpRequest),
        _payload = context.payload,
        _payloadResolver = null;

  @ignore
  final UnderlyingRequest request;

  @include
  List<String> get segments {
    final segments = request.uri.pathSegments;

    if (segments.isEmpty) {
      return [''];
    }

    return segments;
  }

  @include
  String get method => request.method;

  MutableHeadersImpl? _headers;
  @include
  ReadOnlyHeaders get headers =>
      _headers ??= MutableHeadersImpl.from(request.headers);

  @include
  Map<String, String> get queryParameters =>
      Map.unmodifiable(request.uri.queryParameters);

  @include
  Map<String, List<String>> get queryParametersAll =>
      Map.unmodifiable(request.uri.queryParametersAll);

  @include
  Uri get uri => request.uri;

  @override
  List<Object?> get props => _$props;

  Future<(WebSocket, WebSocketRequestContext)> upgradeToWebSocket({
    Duration? ping,
  }) async {
    return (
      await request.upgradeToWebSocket(ping: ping),
      WebSocketRequestContextImpl.fromRequest(this)
    );
  }

  String? _payload;
  final Future<String> Function()? _payloadResolver;

  Future<void> resolvePayload() async {
    if (_payload != null) return;

    if (_payloadResolver == null) {
      throw StateError('Payload resolver not set');
    }

    _payload = await _payloadResolver();
  }

  @override
  String get payload {
    final payload = this._payload;
    if (payload == null) {
      throw StateError('Payload not resolved');
    }

    return payload;
  }

  ReadOnlyBody? _body;
  @override
  ReadOnlyBody get body {
    return _body ??= MutableBodyImpl.fromPayload(payload);
  }
}
