import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/headers/mutable_headers.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/request/request_context_impl.dart';

// ignore: must_be_immutable
class MutableRequestContextImpl extends RequestContextImpl
    implements MutableRequestContext {
  MutableRequestContextImpl.fromRequest(RequestContext request)
      : headers = MutableHeadersImpl.from(request.headers),
        body = MutableBodyImpl.fromPayload(request.payload),
        super.self(request);

  final MutableHeaders headers;
  final ReadOnlyBody body;

  MutableRequestContextImpl getRequestContext() {
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
