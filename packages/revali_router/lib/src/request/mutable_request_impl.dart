import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/mutable_headers.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/request/request_context.dart';

// ignore: must_be_immutable
class MutableRequestImpl extends RequestContextImpl implements MutableRequest {
  MutableRequestImpl.fromRequest(RequestContext request)
      : headers = MutableHeadersImpl.from(request.headers),
        super.self(request);

  final MutableHeaders headers;

  ReadOnlyBody get body => super.payload;

  MutableRequestImpl getRequestContext() {
    return this;
  }

  Map<String, String>? _pathParameters;
  @override
  Map<String, String> get pathParameters =>
      Map.unmodifiable(_pathParameters ?? {});
  void set pathParameters(Map<String, String> pathParameters) {
    _pathParameters = Map.from(pathParameters);
  }
}
