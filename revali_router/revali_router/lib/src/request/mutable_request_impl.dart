import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

// ignore: must_be_immutable
class MutableRequestImpl extends RequestContextImpl implements FullRequest {
  MutableRequestImpl.fromRequest(super.request)
      : headers = MutableHeadersImpl.from(request.headers),
        super.self();

  @override
  final MutableHeaders headers;

  @override
  MutableBody get body => super.payload;

  Map<String, String>? _pathParameters;
  @override
  Map<String, String> get pathParameters =>
      Map.unmodifiable(_pathParameters ?? {});

  set pathParameters(Map<String, String> pathParameters) {
    _pathParameters = Map.from(pathParameters);
  }
}
