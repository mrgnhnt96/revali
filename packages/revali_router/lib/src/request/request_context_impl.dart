import 'dart:io';

import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/request/underlying_request_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'request_context_impl.g.dart';

class RequestContextImpl with EquatableMixin implements RequestContext {
  RequestContextImpl(
    this.request, {
    required ReadOnlyBody payload,
  })  : _payload = payload,
        payloadResolver = null;

  RequestContextImpl._noPayload(
    this.request, {
    required PayloadResolver payloadResolver,
  }) : payloadResolver = payloadResolver;

  factory RequestContextImpl.fromRequest(HttpRequest httpRequest) {
    final request = UnderlyingRequestImpl.fromRequest(httpRequest);

    return RequestContextImpl._noPayload(
      request,
      payloadResolver: () => request.body.resolve(request.headers),
    );
  }

  RequestContextImpl.self(RequestContext context)
      : request = context.request,
        payloadResolver = context.payloadResolver;

  RequestContextImpl.base(RequestContext context, HttpRequest httpRequest)
      : request = UnderlyingRequestImpl.fromRequest(httpRequest),
        payloadResolver = context.payloadResolver;

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

  MutableHeaders? _headers;
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

  Future<WebSocket> upgradeToWebSocket({
    Duration? ping,
  }) async {
    return await request.upgradeToWebSocket(ping: ping);
  }

  ReadOnlyBody? _payload;
  final PayloadResolver? payloadResolver;

  Future<void> resolvePayload() async {
    if (_payload != null) return;

    final resolver = payloadResolver;
    if (resolver == null) {
      throw StateError('Payload resolver not set');
    }

    _payload = await resolver();
  }

  ReadOnlyBody get payload {
    final payload = this._payload;
    if (payload == null) {
      throw StateError('Payload not resolved');
    }

    return payload;
  }
}
