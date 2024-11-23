import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/response/read_only_response.dart';

class SimpleResponse implements ReadOnlyResponse {
  factory SimpleResponse(
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

    response.headers.addAll(
      response.body.headers(MutableHeadersImpl()).map(
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
  final ReadOnlyHeaders headers;
  @override
  ReadOnlyHeaders get joinedHeaders => headers;

  final Map<String, String> rawHeaders;

  @override
  final ReadOnlyBody body;
}
