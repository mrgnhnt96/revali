import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/response/read_only_response.dart';

class SimpleResponse implements ReadOnlyResponse {
  const SimpleResponse._({
    required this.statusCode,
    required this.headers,
    required this.rawHeaders,
    required this.body,
  });

  factory SimpleResponse(
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

    return SimpleResponse._(
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
