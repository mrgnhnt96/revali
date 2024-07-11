import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/request/parts/message.dart';
import 'package:revali_router/src/request/utils/headers.dart';

class Response extends Message {
  Response(
    this.statusCode, {
    Object? body,
    super.encoding,
    super.headers,
  }) : super(body);

  final int statusCode;

  Response.internalServerError({
    Object? body,
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
  }) : this(
          500,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Internal Server Error',
          encoding: encoding,
        );

  Response.notFound(
    Object? body, {
    Map<String, /* String | List<String> */ Object>? headers,
    Encoding? encoding,
  }) : this(
          404,
          headers: body == null ? _adjustErrorHeaders(headers) : headers,
          body: body ?? 'Not Found',
          encoding: encoding,
        );

  Response setBody(Object? body) {
    return Response(
      statusCode,
      body: body,
      encoding: encoding,
      headers: headers,
    );
  }

  void write(HttpResponse httpResponse) {
    try {
      _writeResponse(this, httpResponse);
    } on StateError catch (_) {
      // If the response has already been written to, we can't write it again.
      return;
    }
  }
}

Future<void> _writeResponse(
  Response response,
  HttpResponse httpResponse,
) {
  httpResponse.statusCode = response.statusCode;

  // An adapter must not add or modify the `Transfer-Encoding` parameter, but
  // the Dart SDK sets it by default. Set this before we fill in
  // [response.headers] so that the user or Shelf can explicitly override it if
  // necessary.
  httpResponse.headers.chunkedTransferEncoding = false;

  response.headersAll.forEach((header, value) {
    httpResponse.headers.set(header, value);
  });

  var coding = response.headers['transfer-encoding'];
  if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
    // If the response is already in a chunked encoding, de-chunk it because
    // otherwise `dart:io` will try to add another layer of chunking.
    response = response.setBody(chunkedCoding.decoder.bind(response.read()));

    httpResponse.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
  } else if (response.statusCode >= 200 &&
      response.statusCode != 204 &&
      response.statusCode != 304 &&
      response.contentLength == null &&
      response.mimeType != 'multipart/byteranges') {
    // If the response isn't chunked yet and there's no other way to tell its
    // length, enable `dart:io`'s chunked encoding.
    httpResponse.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
  }

  if (!response.headers.containsKey(HttpHeaders.dateHeader)) {
    httpResponse.headers.date = DateTime.now().toUtc();
  }

  return httpResponse
      .addStream(response.read())
      .then((_) => httpResponse.close());
}

/// Adds content-type information to [headers].
///
/// Returns a new map without modifying [headers]. This is used to add
/// content-type information when creating a 500 response with a default body.
Map<String, Object> _adjustErrorHeaders(
    Map<String, /* String | List<String> */ Object>? headers) {
  if (headers == null || headers['content-type'] == null) {
    return addHeader(headers, 'content-type', 'text/plain');
  }

  final contentTypeValue =
      expandHeaderValue(headers['content-type']!).join(',');
  var contentType =
      MediaType.parse(contentTypeValue).change(mimeType: 'text/plain');
  return addHeader(headers, 'content-type', contentType.toString());
}
