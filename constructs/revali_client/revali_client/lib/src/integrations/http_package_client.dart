import 'package:http/http.dart' as http;
import 'package:revali_client/src/http_client.dart';
import 'package:revali_client/src/http_interceptor.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

class HttpPackageClient implements HttpClient {
  HttpPackageClient({
    http.Client? client,
    List<HttpInterceptor>? interceptors,
  })  : _client = client ?? http.Client(),
        interceptors = interceptors ?? [];

  final http.Client _client;

  @override
  final List<HttpInterceptor> interceptors;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // ignore: unnecessary_await_in_return
    final httpRequest = http.Request(request.method, request.url);

    httpRequest.headers.addAll(request.headers);

    if (request.bodyBytes case final bytes?) {
      httpRequest.bodyBytes = bytes;
    }

    if (request.body case final body when body.isNotEmpty) {
      httpRequest.body = body;
    }

    if (request.encoding case final encoding?) {
      httpRequest.encoding = encoding;
    }

    if (request.contentLength case final contentLength?) {
      httpRequest.contentLength = contentLength;
    }

    for (final HttpInterceptor(:onRequest) in interceptors) {
      try {
        switch (onRequest) {
          case final Future<void> Function(HttpRequest) fn:
            await fn(request);
          case final fn:
            fn(request);
        }
      } catch (e) {
        // swallow
      }
    }

    final response = await _client.send(httpRequest);

    final httpResponse = HttpResponse(
      request: request,
      statusCode: response.statusCode,
      headers: response.headers,
      stream: response.stream,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      contentLength: response.contentLength,
    );

    for (final HttpInterceptor(:onResponse) in interceptors) {
      try {
        switch (onResponse) {
          case final Future<void> Function(HttpResponse) fn:
            await fn(httpResponse);
          case final fn:
            fn(httpResponse);
        }
      } catch (e) {
        // swallow
      }
    }

    return httpResponse;
  }
}
