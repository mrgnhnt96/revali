import 'dart:io';

import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/response/mutable_response_context_impl.dart';
import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/response/read_only_response_context.dart';

class CannedResponse {
  CannedResponse._();

  static ReadOnlyResponseContext notFound({
    Object? body,
    Map<String, String> headers = const {},
  }) {
    return _Response(
      404,
      body: body,
      headers: headers,
    );
  }

  static ReadOnlyResponseContext internalServerError({
    BodyData? body,
    Map<String, String> headers = const {},
  }) {
    return _Response(
      500,
      body: body,
      headers: headers,
    );
  }

  static ReadOnlyResponseContext options({
    required Set<String> allowedMethods,
  }) {
    return _Response(
      200,
      headers: {
        HttpHeaders.allowHeader: allowedMethods.join(', '),
      },
    );
  }

  /// ONLY for web socket **disconnects**
  ///
  /// The expected behavior is that the server will close the connection
  /// without sending any further data (headers, body, etc.)
  ///
  /// This is a special case and should not be used for any other purpose.
  /// Status Code: 1000
  static ReadOnlyResponseContext webSocket() {
    return _Response(1000);
  }

  static ReadOnlyResponseContext redirect(
    String location, {
    int statusCode = 302,
    Map<String, String> headers = const {},
  }) {
    return _Response(
      statusCode,
      headers: {
        'Location': location,
        ...headers,
      },
    );
  }
}

class _Response implements ReadOnlyResponseContext {
  _Response._({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  factory _Response(
    int statusCode, {
    Map<String, String> headers = const {},
    Object? body,
  }) {
    final response =
        MutableResponseContextImpl(requestHeaders: MutableHeadersImpl());
    response.statusCode = statusCode;
    response.headers.addAll(headers);
    if (body != null) {
      response.body = switch (body) {
        BodyData() => body,
        _ => BaseBodyData.from(body),
      };
    }

    return _Response._(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
    );
  }

  @override
  final int statusCode;

  @override
  final ReadOnlyHeaders headers;

  final ReadOnlyBody body;
}
