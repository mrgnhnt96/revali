import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/headers_impl.dart';
import 'package:revali_router/src/response/response_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class SimpleResponse implements Response {
  factory SimpleResponse(
    int statusCode, {
    Map<String, String> headers = const {},
    Object? body,
  }) {
    final response = ResponseImpl(requestHeaders: HeadersImpl())
      ..statusCode = statusCode;
    response.headers.addAll(headers);
    if (body != null) {
      response.body = switch (body) {
        BodyData() => body,
        _ => BaseBodyData<dynamic>.from(body),
      };
    }

    response.headers.addAll(
      response.body.headers(HeadersImpl()).map(
            (key, value) => MapEntry(key, value.join(',')),
          ),
    );

    return SimpleResponse._(
      statusCode: response.statusCode,
      headers: response.headers,
      rawHeaders: headers,
      body: response.body,
    );
  }
  const SimpleResponse._({
    required this.statusCode,
    required this.headers,
    required this.rawHeaders,
    required this.body,
  });

  @override
  final int statusCode;

  @override
  final Headers headers;
  @override
  Headers get joinedHeaders => headers;

  final Map<String, String> rawHeaders;

  @override
  final Body body;

  @override
  set body(Object? data) {
    throw StateError('SimpleResponse is immutable');
  }

  @override
  set headers(Headers value) {
    throw StateError('SimpleResponse is immutable');
  }

  @override
  set statusCode(int value) {
    throw StateError('SimpleResponse is immutable');
  }
}
