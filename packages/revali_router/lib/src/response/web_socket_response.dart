import 'package:revali_router/revali_router.dart';

class WebSocketResponse implements ReadOnlyResponse {
  factory WebSocketResponse(
    int statusCode, {
    Map<String, String> headers = const {},
    Object? body,
  }) {
    final response = MutableResponseImpl(requestHeaders: MutableHeadersImpl())
      ..statusCode = statusCode;
    response.headers.addAll(headers);
    if (body != null) {
      response.body = switch (body) {
        BodyData() => body,
        _ => BaseBodyData<dynamic>.from(body),
      };
    }

    return WebSocketResponse._(
      statusCode: response.statusCode,
      headers: response.headers,
      rawHeaders: headers,
      body: response.body,
    );
  }
  const WebSocketResponse._({
    required this.statusCode,
    required this.headers,
    required this.rawHeaders,
    required this.body,
  });
  @override
  final int statusCode;

  @override
  final ReadOnlyHeaders headers;

  final Map<String, String> rawHeaders;

  @override
  final ReadOnlyBody body;
}
