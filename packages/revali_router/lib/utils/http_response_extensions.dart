import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router/src/payload/payload_impl.dart';
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
    statusCode = response.statusCode;

    MutableHeaders responseHeaders;
    if (response is MutableResponse) {
      responseHeaders = response.headersToSend;
    } else {
      responseHeaders = MutableHeadersImpl.from(response.headers);
    }

    responseHeaders
      ..contentLength ??= 0
      ..mimeType ??= 'text/plain';

    switch (statusCode) {
      case HttpStatus.notModified:
      case HttpStatus.noContent:
        _removeContentRelated(responseHeaders);
      case HttpStatus.notFound:
        _removeAccessControl(responseHeaders);
      default:
        break;
    }

    var chunk = false;

    if (responseHeaders[HttpHeaders.transferEncodingHeader]
        case final coding?) {
      if (!equalsIgnoreAsciiCase(coding, 'identity')) {
        // If the response is already in a chunked encoding, de-chunk it because
        // otherwise `dart:io` will try to add another layer of chunking.
        chunk = true;

        responseHeaders.set(HttpHeaders.transferEncodingHeader, 'chunked');
      } else if (response.statusCode >= 200 &&
          response.statusCode != 204 &&
          response.statusCode != 304 &&
          responseHeaders.contentLength == null &&
          responseHeaders.mimeType != 'multipart/byteranges') {
        // If the response isn't chunked yet and
        // there's no other way to tell its
        // length, enable `dart:io`'s chunked encoding.
        responseHeaders.set(HttpHeaders.transferEncodingHeader, 'chunked');
      }
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

    if (!disallowedMethods.contains(requestMethod) &&
        !disallowedStatuses.contains(response.statusCode)) {
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

      if (chunk && body != null) {
        final payload = PayloadImpl(
          response.body?.read(),
          encoding: responseHeaders.encoding,
        );
        body = chunkedCoding.decoder.bind(payload.read());

        responseHeaders.contentLength = payload.contentLength ?? 0;
      }

      responseHeaders.forEach((key, values) {
        http.headers.set(key, values.join(','));
      });

      if (body != null) {
        await http.addStream(body);
      }
    }

    await http.flush();
    await http.close();
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
