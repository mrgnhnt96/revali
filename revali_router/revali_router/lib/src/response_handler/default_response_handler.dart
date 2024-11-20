import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class DefaultResponseHandler
    with RemoveHeadersMixin
    implements ResponseHandler {
  const DefaultResponseHandler();

  @override
  Future<void> handle(
    ReadOnlyResponse response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    final http = httpResponse;

    Future<void> complete() async {
      await http.flush();
      await http.close();
    }

    final responseHeaders = switch (response) {
      MutableResponse() => response.headersToSend,
      _ => MutableResponseImpl.from(response).headersToSend,
    }
      ..mimeType ??= 'text/plain';

    http.statusCode = response.statusCode;

    switch (response.statusCode) {
      case HttpStatus.notModified:
      case HttpStatus.noContent:
        removeContentRelated(responseHeaders);
      case HttpStatus.notFound:
        removeAccessControl(responseHeaders);
      default:
        break;
    }

    var deChunkBeforeSending = false;
    if (responseHeaders.transferEncoding case final transfer?) {
      if (!equalsIgnoreAsciiCase(transfer, 'identity')) {
        // If the response is already in a chunked encoding, de-chunk it because
        // otherwise `dart:io` will try to add another layer of chunking.
        deChunkBeforeSending = true;
        responseHeaders.transferEncoding = 'chunked';
      }
    } else if (response.statusCode >= 200 &&
        response.statusCode != 204 &&
        response.statusCode != 304 &&
        responseHeaders.contentLength == null &&
        responseHeaders.mimeType != 'multipart/byteranges') {
      // If the response isn't chunked yet and
      // there's no other way to tell its
      // length, enable `dart:io`'s chunked encoding.
      responseHeaders.transferEncoding = 'chunked';
    } else if (responseHeaders.contentLength == null) {
      responseHeaders.contentLength = 0;
    }

    if (!responseHeaders.keys.contains(HttpHeaders.dateHeader)) {
      http.headers.date = DateTime.now().toUtc();
    }

    /// Disallow body for certain status codes
    const disallowedStatuses = {
      HttpStatus.noContent,
      HttpStatus.notModified,
    };

    /// Disallow body for certain methods
    const disallowedMethods = {
      'HEAD',
      'OPTIONS',
    };

    if (disallowedMethods.contains(context.method) &&
        disallowedStatuses.contains(response.statusCode)) {
      await complete();

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

    if (deChunkBeforeSending && body != null) {
      body = chunkedCoding.decoder.bind(body);
    }

    responseHeaders.forEach((key, values) {
      http.headers.set(key, values.join(','));
    });

    if (body != null) {
      await http.addStream(body);
    }

    await complete();
  }
}
