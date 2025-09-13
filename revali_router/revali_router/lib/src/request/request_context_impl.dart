import 'dart:io';

import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:revali_router/src/exceptions/unresolved_payload_exception.dart';
import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router/src/request/underlying_request_impl.dart';
import 'package:revali_router/utils/coerce.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'request_context_impl.g.dart';

// ignore: must_be_immutable
class RequestContextImpl with EquatableMixin implements RequestContext {
  RequestContextImpl(
    this.request, {
    required Body payload,
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

  Headers? _headers;
  @override
  @include
  Headers get headers => _headers ??= HeadersImpl.from(request.headers);

  @override
  @include
  Map<String, dynamic> get queryParameters {
    Iterable<MapEntry<String, dynamic>> entries() sync* {
      for (final MapEntry(:key, :value)
          in request.uri.queryParameters.entries) {
        yield MapEntry(key, coerce(value));
      }
    }

    return Map.unmodifiable(Map.fromEntries(entries()));
  }

  @override
  @include
  Map<String, List<dynamic>> get queryParametersAll {
    Iterable<MapEntry<String, List<dynamic>>> entries() sync* {
      for (final MapEntry(:key, :value)
          in request.uri.queryParametersAll.entries) {
        yield MapEntry(key, value.map(coerce).toList());
      }
    }

    return Map.unmodifiable(Map.fromEntries(entries()));
  }

  @override
  @include
  Uri get uri => request.uri;

  @override
  Future<WebSocket> upgradeToWebSocket({
    Duration? ping,
  }) async {
    return request.upgradeToWebSocket(ping: ping);
  }

  Body? _payload;
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

  Body get payload {
    final payload = _payload;
    if (payload == null) {
      throw const UnresolvedPayloadException();
    }

    return payload;
  }

  Payload get originalPayload => request.body;

  @override
  Future<void> close() async {
    await originalPayload.close();
    for (final cleanUp in _cleanUps) {
      cleanUp();
    }
  }

  @override
  List<Object?> get props => _$props;

  final _cleanUps = <void Function()>[];

  @override
  void addCleanUp(void Function() cleanUp) {
    _cleanUps.add(cleanUp);
  }
}
