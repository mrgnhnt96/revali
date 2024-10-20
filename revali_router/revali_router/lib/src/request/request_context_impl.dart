import 'dart:io';

import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_router/src/exceptions/unresolved_payload_exception.dart';
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
    required this.payloadResolver,
  });

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

  @override
  @ignore
  final UnderlyingRequest request;

  @override
  @include
  List<String> get segments {
    final segments = request.uri.pathSegments;

    if (segments.isEmpty) {
      return [''];
    }

    return segments;
  }

  @override
  @include
  String get method => request.method;

  MutableHeaders? _headers;
  @override
  @include
  ReadOnlyHeaders get headers =>
      _headers ??= MutableHeadersImpl.from(request.headers);

  @override
  @include
  Map<String, String> get queryParameters =>
      Map.unmodifiable(request.uri.queryParameters);

  @override
  @include
  Map<String, List<String>> get queryParametersAll =>
      Map.unmodifiable(request.uri.queryParametersAll);

  @override
  @include
  Uri get uri => request.uri;

  @override
  Future<WebSocket> upgradeToWebSocket({
    Duration? ping,
  }) async {
    return request.upgradeToWebSocket(ping: ping);
  }

  ReadOnlyBody? _payload;
  @override
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
    final payload = _payload;
    if (payload == null) {
      throw const UnresolvedPayloadException();
    }

    return payload;
  }

  Payload get originalPayload => request.body;

  @override
  List<Object?> get props => _$props;
}