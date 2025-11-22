import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

// ignore: must_be_immutable
class RequestImpl extends RequestContextImpl implements FullRequest {
  RequestImpl.fromRequest(super.request)
      : headers = HeadersImpl.from(request.headers),
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
}
