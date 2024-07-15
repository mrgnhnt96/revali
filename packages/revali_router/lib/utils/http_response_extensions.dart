import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router_core/revali_router_core.dart';

extension HttpResponseX on HttpResponse {
  Future<void> send(
    ReadOnlyResponseContext response, {
    String? requestMethod,
  }) async {
    final _headers = response.headers;
    final http = this;

    Stream<List<int>>? _body;

    if (_headers[HttpHeaders.transferEncodingHeader] case final coding?) {
      if (!equalsIgnoreAsciiCase(coding, 'identity')) {
        // If the response is already in a chunked encoding, de-chunk it because
        // otherwise `dart:io` will try to add another layer of chunking.
        _body = chunkedCoding.decoder
            .bind(PayloadImpl(response.body?.read()).read());

        http.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
      } else if (response.statusCode >= 200 &&
          response.statusCode != 204 &&
          response.statusCode != 304 &&
          _headers.contentLength == null &&
          _headers.mimeType != 'multipart/byteranges') {
        // If the response isn't chunked yet and there's no other way to tell its
        // length, enable `dart:io`'s chunked encoding.
        http.headers.set(HttpHeaders.transferEncodingHeader, 'chunked');
      }
    }

    if (!_headers.keys.contains(HttpHeaders.dateHeader)) {
      http.headers.date = DateTime.now().toUtc();
    }

    if (response.body case final responseBody? when !responseBody.isNull) {
      if (_headers.range case final range? when responseBody is FileBodyData) {
        final (start, end) = range;
        _body ??= responseBody.range(start, end);
      } else {
        _body ??= responseBody.read();
      }
    }

    if (_body != null &&
        requestMethod != 'HEAD' &&
        response.statusCode != HttpStatus.noContent) {
      await http.addStream(_body);
    }

    await http.flush();
    await http.close();
  }
}
