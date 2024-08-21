import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router/src/response/web_socket_response.dart';
import 'package:revali_router_core/revali_router_core.dart';

extension HttpResponseX on HttpResponse {
  Future<void> send(
    ReadOnlyResponse response, {
    String? requestMethod,
  }) async {
    // WebSockets are already responded to, and cannot be responded to again.
    if (response is WebSocketResponse) {
      return;
    }

    final http = this;

    MutableHeaders responseHeaders;
    if (response is MutableResponse) {
      responseHeaders = response.headersToSend;
    } else {
      final mutableResponse = MutableResponseImpl.from(response);

      responseHeaders = mutableResponse.headersToSend;
    }

    responseHeaders.mimeType ??= 'text/plain';
    http.statusCode = response.statusCode;

    switch (response.statusCode) {
      case HttpStatus.notModified:
      case HttpStatus.noContent:
        _removeContentRelated(responseHeaders);
      case HttpStatus.notFound:
        _removeAccessControl(responseHeaders);
      default:
        break;
    }

    var useChunking = false;
    var deChunkBeforeSending = false;
    if (responseHeaders.transferEncoding case final transfer?) {
      if (!equalsIgnoreAsciiCase(transfer, 'identity')) {
        // If the response is already in a chunked encoding, de-chunk it because
        // otherwise `dart:io` will try to add another layer of chunking.
        deChunkBeforeSending = true;
        useChunking = true;
      }
    } else if (response.statusCode >= 200 &&
        response.statusCode != 204 &&
        response.statusCode != 304 &&
        responseHeaders.contentLength == null &&
        responseHeaders.mimeType != 'multipart/byteranges') {
      // If the response isn't chunked yet and
      // there's no other way to tell its
      // length, enable `dart:io`'s chunked encoding.
      useChunking = true;
    } else if (responseHeaders.contentLength == null) {
      responseHeaders.contentLength = 0;
    }

    if (!responseHeaders.keys.contains(HttpHeaders.dateHeader)) {
      http.headers.date = DateTime.now().toUtc();
    }

    const disallowedStatuses = {
      HttpStatus.noContent,
      HttpStatus.notModified,
    };

    const disallowedMethods = {
      'HEAD',
      'OPTIONS',
    };

    if (disallowedMethods.contains(requestMethod) &&
        disallowedStatuses.contains(response.statusCode)) {
      await _complete();

      return;
    }

    Stream<List<int>>? body;
    if (response.body case final responseBody? when !responseBody.isNull) {
      if (responseHeaders.range case final range?
          when responseBody is FileBodyData) {
        final (start, end) = range;
        body = responseBody.range(start, end);
      } else {
        body = responseBody.read();
      }
    }

    if (useChunking && body != null) {
      responseHeaders.transferEncoding = 'chunked';

      if (deChunkBeforeSending) {
        body = chunkedCoding.decoder.bind(body);
      }

      body = chunkedCoding.encoder.bind(body);
    }

    responseHeaders.forEach((key, values) {
      http.headers.set(key, values.join(','));
    });

    if (body != null) {
      await http.addStream(body);
    }

    await _complete();
  }

  Future<void> _complete() async {
    await flush();
    await close();
  }
}

void _removeContentRelated(MutableHeaders headers) {
  headers
    ..remove(HttpHeaders.contentTypeHeader)
    ..remove(HttpHeaders.contentLengthHeader)
    ..remove(HttpHeaders.contentEncodingHeader)
    ..remove(HttpHeaders.transferEncodingHeader)
    ..remove(HttpHeaders.contentRangeHeader)
    ..remove(HttpHeaders.acceptRangesHeader)
    ..remove(HttpHeaders.contentDisposition)
    ..remove(HttpHeaders.contentLanguageHeader)
    ..remove(HttpHeaders.contentLocationHeader)
    ..remove(HttpHeaders.contentMD5Header);
}

void _removeAccessControl(MutableHeaders headers) {
  headers
    ..remove(HttpHeaders.allowHeader)
    ..remove(HttpHeaders.accessControlAllowOriginHeader)
    ..remove(HttpHeaders.accessControlAllowCredentialsHeader)
    ..remove(HttpHeaders.accessControlExposeHeadersHeader)
    ..remove(HttpHeaders.accessControlMaxAgeHeader)
    ..remove(HttpHeaders.accessControlAllowMethodsHeader)
    ..remove(HttpHeaders.accessControlAllowHeadersHeader)
    ..remove(HttpHeaders.accessControlRequestHeadersHeader)
    ..remove(HttpHeaders.accessControlRequestMethodHeader);
}
