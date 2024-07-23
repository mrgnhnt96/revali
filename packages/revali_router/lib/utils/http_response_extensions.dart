import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/payload/payload_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

extension HttpResponseX on HttpResponse {
  Future<void> send(
    ReadOnlyResponse response, {
    String? requestMethod,
  }) async {
    // WebSockets are a special case.
    if (response.statusCode >= 1000) {
      return;
    }

    final http = this;
    statusCode = response.statusCode;

    final _headers = response.headers;
    _headers.forEach((key, values) {
      http.headers.set(key, values.join(','));
    });

    bool chunk = false;

    if (_headers[HttpHeaders.transferEncodingHeader] case final coding?) {
      if (!equalsIgnoreAsciiCase(coding, 'identity')) {
        // If the response is already in a chunked encoding, de-chunk it because
        // otherwise `dart:io` will try to add another layer of chunking.
        chunk = true;

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
      Stream<List<int>>? _body;
      if (response.body case final responseBody? when !responseBody.isNull) {
        if (_headers.range case final range?
            when responseBody is FileBodyData) {
          final (start, end) = range;
          _body = responseBody.range(start, end);
        } else {
          _body = responseBody.read();
        }
      }

      if (chunk && _body != null) {
        _body = chunkedCoding.decoder
            .bind(PayloadImpl(response.body?.read()).read());
      }

      if (_body != null) {
        await http.addStream(_body);
      }
    }

    await http.flush();
    await http.close();
  }
}
