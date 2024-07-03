import 'package:revali_router/src/request/request_context.dart';
import 'package:shelf/shelf.dart';

class MutableRequestContext extends RequestContext {
  MutableRequestContext(Request request)
      : _headers = Map.from(request.headers),
        super(request);
  MutableRequestContext.from(RequestContext request)
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

  MutableRequestContext merge(MutableRequestContext other) {
    final merged = MutableRequestContext.from(this);

    merged._headers.addAll(other._headers);

    return merged;
  }
}
