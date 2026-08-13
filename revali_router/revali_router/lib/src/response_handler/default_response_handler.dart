import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';

class DefaultResponseHandler
    with RemoveHeadersMixin
    implements ResponseHandler {
  const DefaultResponseHandler({
    this.compression = const CompressionSettings(),
  });

  final CompressionSettings compression;

  /// Whether this response should be gzipped for this client.
  ///
  /// Deliberately conservative. Only bodies of a known length are compressed,
  /// which leaves streaming responses alone — gzip buffers, so compressing a
  /// stream would hold chunks back that the handler meant to flush.
  /// Partial content is excluded too: compressing a byte range would make the
  /// range describe bytes the client did not ask for.
  bool _shouldCompress(
    Headers headers,
    RequestContext context,
    int statusCode,
  ) {
    if (!compression.allows(headers.mimeType)) {
      return false;
    }

    if (headers.get(HttpHeaders.contentEncodingHeader) != null) {
      return false;
    }

    if (statusCode == HttpStatus.partialContent || headers.range != null) {
      return false;
    }

    if (headers.contentLength case final length?
        when length >= compression.minBytes) {
      return _acceptsGzip(context);
    }

    return false;
  }

  bool _acceptsGzip(RequestContext context) {
    final values = context.headers.getAll(HttpHeaders.acceptEncodingHeader) ??
        const <String>[];

    for (final value in values) {
      for (final part in value.split(',')) {
        // Strip any q-value: "gzip;q=0.8".
        final token = part.split(';').first.trim();

        if (equalsIgnoreAsciiCase(token, 'gzip')) {
          return true;
        }
      }
    }

    return false;
  }

  static String? _cachedHttpDate;
  static int _cachedHttpDateSecond = -1;

  static String _httpDateNow() {
    final now = DateTime.now().toUtc();
    final second = now.millisecondsSinceEpoch ~/ 1000;
    if (second != _cachedHttpDateSecond) {
      _cachedHttpDateSecond = second;
      _cachedHttpDate = HttpDate.format(now);
    }
    return _cachedHttpDate!;
  }

  @override
  Future<void> handle(
    Response response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    final http = httpResponse;

    Future<void> complete() async {
      await http.flush();
      try {
        await http.close();
      } catch (_) {
        // ignore, connection was already closed
      }
      await context.close();
    }

    final responseHeaders = response.joinedHeaders..mimeType ??= 'text/plain';

    http.statusCode = response.statusCode;

    switch (response.statusCode) {
      case HttpStatus.notModified:
      case HttpStatus.noContent:
        removeContentRelated(responseHeaders);
      default:
        break;
    }

    // Decided before the transfer-encoding block below, which branches on
    // contentLength -- gzipping makes the declared length wrong, so it has to
    // be cleared first and the response sent chunked.
    final compress = _shouldCompress(
      responseHeaders,
      context,
      response.statusCode,
    );

    if (compress) {
      responseHeaders
        ..[HttpHeaders.contentEncodingHeader] = 'gzip'
        ..contentLength = null;

      // Caches key on this: the same URL now has a gzipped and an
      // uncompressed variant, and serving the wrong one breaks the client.
      final vary = responseHeaders.get(HttpHeaders.varyHeader);
      responseHeaders[HttpHeaders.varyHeader] = switch (vary) {
        null || '' => HttpHeaders.acceptEncodingHeader,
        final existing
            when existing.toLowerCase().contains('accept-encoding') =>
          existing,
        final existing => '$existing, ${HttpHeaders.acceptEncodingHeader}',
      };
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
    } else {
      responseHeaders.contentLength ??= 0;
    }

    if (!responseHeaders.keys.contains(HttpHeaders.dateHeader)) {
      http.headers.set(HttpHeaders.dateHeader, _httpDateNow());
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
    if (response.body case final responseBody when !responseBody.isNull) {
      if ((responseHeaders.range, responseBody.data)
          case (final range?, final FileBodyData data)
          when responseBody is FileBodyData) {
        final (start, end) = range;
        body = data.range(start, end);
      } else {
        body = responseBody.read();
      }
    }

    if (deChunkBeforeSending && body != null) {
      body = chunkedCoding.decoder.bind(body);
    }

    if (compress && body != null) {
      body = gzip.encoder.bind(body);
    }

    responseHeaders.forEach((key, values) {
      // Set-Cookie must never be comma-joined into a single line -- each
      // cookie needs its own header line (RFC 6265 §4.1.1); comma-joining
      // is also ambiguous since a cookie's Expires attribute may itself
      // contain commas.
      if (equalsIgnoreAsciiCase(key, HttpHeaders.setCookieHeader)) {
        for (final value in values) {
          http.headers.add(key, value);
        }
      } else {
        http.headers.set(key, values.join(','));
      }
    });

    if (http.connectionInfo == null) {
      // Connection is closed, so we can't send the response.
      await complete();
      return;
    }

    if (body != null) {
      await http.addStream(body);
    }

    await complete();
  }
}
