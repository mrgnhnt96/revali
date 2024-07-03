import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:shelf/shelf.dart';

// ignore: must_be_immutable
class MutableRequestContextImpl extends RequestContext
    implements MutableRequestContext {
  MutableRequestContextImpl(Request request)
      : _headers = Map.from(request.headers),
        super(request);
  MutableRequestContextImpl.from(RequestContext request)
      : _headers = Map.from(request.headers),
        super.from(request);

  final Map<String, String> _headers;

  Map<String, String> get headers => Map.unmodifiable(_headers);

  void setHeader(String key, String value) {
    _headers[key] = value;
  }

  void removeHeader(String key) {
    _headers.remove(key);
  }

  MutableRequestContextImpl merge(MutableRequestContextImpl other) {
    final merged = MutableRequestContextImpl.from(this);

    merged._headers.addAll(other._headers);

    return merged;
  }

  int? _statusCode;
  int get statusCode => _statusCode ?? 200;
  void set statusCode(int value) {
    _statusCode = value;
  }

  Object? _body;
  Object? get body => _body;
  void set body(Object? value) {
    _body = value;
  }

  MutableRequestContextImpl getContext() {
    return this;
  }

  Response getSuccessResponse([int defaultStatusCode = 200]) {
    var code = _statusCode ?? defaultStatusCode;

    if (code < 200 || code >= 300) {
      code = 200;
    }

    return Response(
      code,
      body: _body,
      headers: _headers,
    );
  }

  Response getErrorResponse([int defaultStatusCode = 400]) {
    var code = _statusCode ?? defaultStatusCode;
    if (code < 400 || code >= 600) {
      code = 400;
    }

    return Response(
      code,
      body: _body,
      headers: _headers,
    );
  }
}
