import 'dart:convert';

import 'package:revali_client/src/cookie_parser.dart';
import 'package:revali_client/src/http_client.dart';
import 'package:revali_client/src/http_interceptor.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';
import 'package:revali_client/src/integrations/http_package_client.dart';
import 'package:revali_client/src/retry_policy.dart';
import 'package:revali_client/src/server_exception.dart';
import 'package:revali_client/src/storage.dart';

class RevaliClient {
  RevaliClient({
    required this.storage,
    HttpClient? client,
    this.baseUrl,
    this.timeout,
    this.retry = const RetryPolicy.none(),
  }) : _client = client ?? HttpPackageClient();

  final Storage storage;
  final HttpClient _client;
  final String? baseUrl;

  /// How long to wait for a response before giving up.
  ///
  /// Covers reaching the far side and getting its status and headers back, not
  /// the time spent streaming a large body afterwards — a slow download is not
  /// the same failure as a peer that never answers, and cutting the first off
  /// at the same deadline as the second would break long transfers.
  ///
  /// Null waits indefinitely, which is the previous behaviour and a poor
  /// default in a service mesh: a peer that accepts connections and never
  /// replies otherwise holds this request forever.
  final Duration? timeout;

  /// When a failed request is sent again. Off by default.
  final RetryPolicy retry;

  List<HttpInterceptor> get interceptors => _client.interceptors;

  /// [headers] Accepts either a Map<String, List<String>>
  /// or a Map<String, String>.
  ///
  /// [query] Accepts either a Map<String, List<String>>
  /// or a Map<String, String>.
  Future<HttpResponse> request({
    required String method,
    required String path,
    Map<String, dynamic>? headers,
    Object? body,
    Map<String, dynamic> query = const {},
  }) async {
    assert(path.isNotEmpty, 'Path cannot be empty');

    String formQuery() {
      if (query.isEmpty) {
        return '';
      }

      final pairs = <String>[];

      void write(String key, dynamic value) {
        if (value == null) return;

        if (value is List) {
          for (final e in value) {
            write(key, e);
          }
          return;
        }

        // Percent encoded because the far side decodes: the router reads
        // `Uri.queryParametersAll`, so anything written raw here is read as
        // syntax there. A `#` in a value truncates the request at the client
        // and surfaces as a deserialization error on the server, which is a
        // long way from the call site that supplied the value.
        //
        // jsonEncode is allowed to throw: a value it cannot represent is a
        // mistake at the call site, and its `toString()` would be sent as if
        // it were the value.
        final encoded = switch (value) {
          String() => value,
          _ => jsonEncode(value),
        };

        pairs.add(
          '${Uri.encodeQueryComponent(key)}'
          '=${Uri.encodeQueryComponent(encoded)}',
        );
      }

      query.forEach(write);

      final buffer = pairs.join('&');

      if (buffer.isEmpty) {
        return '';
      }

      return '?$buffer';
    }

    final fullPath = switch ((path[0], baseUrl)) {
      ('/', final String base) => '$base$path${formQuery()}',
      ('/', null) => throw Exception('Base URL not set'),
      _ => '$path${formQuery()}',
    };

    final uri = Uri.parse(fullPath);

    final request = HttpRequest(method: method, url: uri);

    if (headers != null) {
      void addHeader(String key, dynamic value) {
        if (value == null) return;

        if (value is List) {
          request.headers[key] = value.map((e) => '$e').join(',');
        } else {
          request.headers[key] = value.toString();
        }
      }

      headers.forEach(addHeader);
    }

    switch (body) {
      case List<int>():
        request.bodyBytes = body;
        request.headers['content-type'] = 'application/octet-stream';

      case List<dynamic>():
      case Map<dynamic, dynamic>():
        request.body = jsonEncode(body);
        request.headers['content-type'] = 'application/json';

      case String():
        request.body = body;
        request.headers['content-type'] = 'text/plain';

      // Sent incrementally, so a large upload never has to fit in memory.
      // The server side of this is `@Body() Stream<List<int>>`, which reads
      // the payload as it arrives.
      case Stream<List<int>>():
        request.bodyStream = body;
        request.headers['content-type'] = 'application/octet-stream';

      case Stream<String>():
        request.bodyStream = body.map(utf8.encode);
        request.headers['content-type'] = 'text/plain';

      case Stream<dynamic>():
        // Anything else would need a framing format both ends agree on
        // (NDJSON, length-prefixing), and the server has no binding for one.
        // Better to say so than to invent a format silently.
        throw ArgumentError(
          'Cannot send a ${body.runtimeType} as a request body. Streamed '
          'bodies must be Stream<List<int>> or Stream<String>; map the '
          'stream to one of those before sending it.',
        );

      case null:
        break;
      default:
        request.body = jsonEncode(body);
        request.headers['content-type'] = 'application/json';
    }

    final response = await _send(request);

    final hasException = switch (response.statusCode) {
      >= 200 && < 300 => false,
      _ => true,
    };

    if (hasException) {
      // `cast`, because `transform` is generic on the stream's *runtime* type:
      // a transport handing back a `Stream<Uint8List>` (which `package:http`
      // does) cannot take a `StreamTransformer<List<int>, String>` and throws
      // a TypeError instead of reading the body. Only the error path decodes
      // a body here, which is why it went unnoticed.
      final body = await response.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .join();

      throw ServerException.fromBody(
        message: response.reasonPhrase ?? 'Unknown error',
        statusCode: response.statusCode,
        body: body,
      );
    }

    if (response.headers['set-cookie'] case final String cookies
        when cookies.isNotEmpty) {
      final parser = CookieParser(cookies);

      if (parser.parse() case final cookies when cookies.isNotEmpty) {
        await storage.saveAll(cookies);
      }
    }

    return response;
  }

  /// Sends [request], applying [timeout] and [retry].
  ///
  /// Deliberately wraps the transport rather than living inside
  /// [HttpPackageClient], so a custom [HttpClient] — a test double, a
  /// different HTTP package — gets the same behaviour instead of having to
  /// reimplement it.
  Future<HttpResponse> _send(HttpRequest request) async {
    final retryable = retry.allows(request);

    var attempt = 0;
    while (true) {
      attempt++;

      HttpResponse response;
      try {
        response = await _sendOnce(request);
      } catch (_) {
        if (!retryable || !retry.shouldRetryError(attempt)) {
          rethrow;
        }

        await Future<void>.delayed(retry.delayFor(attempt));
        continue;
      }

      if (!retryable || !retry.shouldRetryResponse(response, attempt)) {
        return response;
      }

      final delay = retry.delayFor(attempt, response);

      // The discarded response still owns a socket. Draining it releases the
      // connection instead of leaking one per retry.
      await response.stream.drain<void>().catchError((Object _) {});

      await Future<void>.delayed(delay);
    }
  }

  Future<HttpResponse> _sendOnce(HttpRequest request) {
    final sent = _client.send(request);

    if (timeout case final limit?) {
      return sent.timeout(limit);
    }

    return sent;
  }
}
