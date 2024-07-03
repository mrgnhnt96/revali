import 'package:revali_router/src/response/mutable_response_context.dart';
import 'package:shelf/shelf.dart';

class MutableResponseContextImpl implements MutableResponseContext {
  MutableResponseContextImpl() : _headers = <String, String>{};

  final Map<String, String> _headers;

  Map<String, String> get headers => Map.unmodifiable(_headers);

  void setHeader(String key, String value) {
    _headers[key] = value;
  }

  void removeHeader(String key) {
    _headers.remove(key);
  }

  int? _statusCode;
  @override
  int get statusCode => _statusCode ?? 200;
  @override
  void set statusCode(int value) {
    _statusCode = value;
  }

// TODO(mrgnhnt): probably create a class for the body
// That way it will be easier to change from Map to Static file, etc
  Map<String, dynamic>? _body;
  @override
  Map<String, dynamic>? get body => _body;
  @override
  void set body(Object? value) {
    (_body ??= {})['data'] = value;
  }

  Response get([int defaultStatusCode = 200]) {
    return Response(
      _statusCode ?? defaultStatusCode,
      body: _body,
      headers: _headers,
    );
  }

  Response getSuccess([int defaultStatusCode = 200]) {
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

  Response getError([int defaultStatusCode = 400]) {
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

  @override
  void addToBody(String key, Object value) async {
    if (key == 'data') {
      throw ArgumentError('The key `data` is reserved for the body');
    }

    (_body ??= {})[key] = value;
  }
}
