import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/payload/payload_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

extension HttpResponseX on HttpResponse {
  Future<void> send(
    ReadOnlyResponseContext response, {
    RequestContext? request,
  }) async {
    statusCode = response.statusCode;
    response.headers.forEach((key, value) {
      headers.add(key, value);
    });

    response.body?.headers(request?.headers).forEach((key, value) {
      headers.add(key, value);
    });

    Stream<List<int>>? body;

    var coding = response.headers[HttpHeaders.transferEncodingHeader];
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      // If the response is already in a chunked encoding, de-chunk it because
      // otherwise `dart:io` will try to add another layer of chunking.
      body = chunkedCoding.decoder.bind(
        PayloadImpl(response.body?.read()).read(),
      );

      headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    } else if (response.statusCode >= 200 &&
        response.statusCode != 204 &&
        response.statusCode != 304 &&
        response.body?.contentLength == null &&
        response.body?.mimeType != 'multipart/byteranges') {
      // If the response isn't chunked yet and there's no other way to tell its
      // length, enable `dart:io`'s chunked encoding.
      headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
    }

    if (!response.headers.keys.contains(HttpHeaders.dateHeader)) {
      headers.date = DateTime.now().toUtc();
    }

    if (response.body case final responseBody? when !responseBody.isNull) {
      if (response.headers.range case final range?
          when responseBody is FileBodyData) {
        final (start, end) = range;
        body ??= responseBody.range(start, end);
      } else {
        body ??= responseBody.read();
      }
    }

    if (body != null && request?.method != 'HEAD') {
      await addStream(body);
    }

    await flush();
    await close();
  }
}
