import 'package:revali_router/revali_router.dart';

class WebSocketResponse implements ReadOnlyResponse {
  const WebSocketResponse._({
    required this.statusCode,
    required this.headers,
    required this.rawHeaders,
    required this.body,
  });

  factory WebSocketResponse(
    int statusCode, {
    Map<String, String> headers = const {},
    Object? body,
  }) {
    final response = MutableResponseImpl(requestHeaders: MutableHeadersImpl());
    response.statusCode = statusCode;
    response.headers.addAll(headers);
    if (body != null) {
      response.body = switch (body) {
        BodyData() => body,
        _ => BaseBodyData.from(body),
      };
    }

    return WebSocketResponse._(
      statusCode: response.statusCode,
      headers: response.headers,
      rawHeaders: headers,
      body: response.body,
    );
  }
  @override
  final int statusCode;

  @override
  final ReadOnlyHeaders headers;

  final Map<String, String> rawHeaders;

  final ReadOnlyBody body;
}
