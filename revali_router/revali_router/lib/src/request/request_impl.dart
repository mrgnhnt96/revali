import 'package:revali_router/src/headers/request_headers_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

// ignore: must_be_immutable
class RequestImpl extends RequestContextImpl implements FullRequest {
  RequestImpl.fromRequest(super.request)
      : headers = RequestHeadersImpl.from(request.headers),
        super.self();

  @override
  final Headers headers;

  @override
  Body get body => super.payload;

  Map<String, String>? _pathParameters;
  @override
  Map<String, String> get pathParameters =>
      Map.unmodifiable(_pathParameters ?? {});

  set pathParameters(Map<String, String> pathParameters) {
    _pathParameters = Map.from(pathParameters);
  }

  set wildcardParameters(Map<String, List<String>> wildcardParameters) {
    _wildcardParameters = Map.from(wildcardParameters);
  }

  Map<String, List<String>>? _wildcardParameters;
  @override
  Map<String, List<String>> get wildcardParameters =>
      Map.unmodifiable(_wildcardParameters ?? {});

  @override
  String? get ip => request.ip;
}
