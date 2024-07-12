import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/request/parts/payload.dart';
import 'package:revali_router/src/response/read_only_response_context.dart';

extension HttpResponseX on HttpResponse {
  Future<void> send(ReadOnlyResponseContext response) async {
    statusCode = response.statusCode;
    response.headers.forEach((key, value) {
      headers.add(key, value);
    });

    Stream<List<int>>? body;

    var coding = response.headers['transfer-encoding'];
    if (coding != null && !equalsIgnoreAsciiCase(coding, 'identity')) {
      // If the response is already in a chunked encoding, de-chunk it because
      // otherwise `dart:io` will try to add another layer of chunking.
      body = chunkedCoding.decoder.bind(
        Payload(response.body?.read(), encoding).read(),
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

    body ??= response.body?.read();

    if (body != null) {
      await addStream(body);
    }

    await flush();
    await close();
  }
}
