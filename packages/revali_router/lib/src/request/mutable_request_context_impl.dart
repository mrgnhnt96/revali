import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/request/parts/payload.dart';
import 'package:revali_router/src/request/request_context.dart';

// ignore: must_be_immutable
class MutableRequestContextImpl extends RequestContext
    implements MutableRequestContext {
  MutableRequestContextImpl.from(RequestContext request)
      : _headers = Map.from(request.headers),
        super.self(request);

  final Map<String, String> _headers;

  Map<String, String> get headers => Map.unmodifiable(_headers);

  void setHeader(String key, String value) {
    _headers[key] = value;
  }

  void removeHeader(String key) {
    _headers.remove(key);
  }

  MutableRequestContextImpl getRequestContext() {
    return this;
  }

  String? _body;

  @override
  Future<String?> get body async {
    if (_body != null) {
      return _body;
    }

    final body = await super.body;
    return _body = body;
  }

  void setPathParameters(Map<String, String> pathParameters) {
    _pathParameters = Map.from(pathParameters);
  }

  @override
  Map<String, String> get pathParameters =>
      Map.unmodifiable(_pathParameters ?? {});
  Map<String, String>? _pathParameters;

  Future<void> overrideBody(Object? event) async {
    _body = await Payload(event, encoding).readAsString();
  }
}
