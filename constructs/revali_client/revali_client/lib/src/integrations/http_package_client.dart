import 'package:http/http.dart' as http;
import 'package:revali_client/src/http_client.dart';
import 'package:revali_client/src/http_interceptor.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';
import 'package:revali_client/src/integrations/credentials/credentials_io.dart'
    if (dart.library.js_interop) 'package:revali_client/src/integrations/credentials/credentials_web.dart';

class HttpPackageClient implements HttpClient {
  HttpPackageClient({http.Client? client, List<HttpInterceptor>? interceptors})
    : _client = client ?? http.Client(),
      interceptors = interceptors ?? [] {
    enableCredentials(_client);
  }

  final http.Client _client;

  @override
  final List<HttpInterceptor> interceptors;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    for (final interceptor in interceptors) {
      // Deliberately unguarded. An interceptor that throws has not done its
      // job, and swallowing that put a half-prepared request on the wire --
      // a failed auth interceptor became a confusing 401 from the peer rather
      // than an error at the point that actually broke.
      if (await interceptor.onRequest(request) case final short?) {
        return short;
      }
    }

    // Built *after* the interceptors, so one that rewrites the body or the
    // encoding is reflected in what is actually sent, not just the headers.
    final httpRequest = _buildRequest(request)..headers.addAll(request.headers);

    final response = await _client.send(httpRequest);

    var httpResponse = HttpResponse(
      request: request,
      statusCode: response.statusCode,
      headers: response.headers,
      stream: response.stream,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      contentLength: response.contentLength,
    );

    for (final interceptor in interceptors) {
      if (await interceptor.onResponse(httpResponse) case final replacement?) {
        httpResponse = replacement;
      }
    }

    return httpResponse;
  }

  http.BaseRequest _buildRequest(HttpRequest request) {
    if (request.bodyStream case final stream?) {
      return _StreamedRequest(request.method, request.url, stream)
        ..contentLength = request.contentLength;
    }

    final httpRequest = http.Request(request.method, request.url);

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

    return httpRequest;
  }
}

/// Sends a body straight from a stream.
///
/// `http.StreamedRequest` requires the caller to pump its sink, which means
/// starting that pump before `send` and cancelling it if the request fails.
/// Subclassing `BaseRequest` instead lets the stream be handed over whole, so
/// the transport pulls from it and backpressure is preserved.
class _StreamedRequest extends http.BaseRequest {
  _StreamedRequest(super.method, super.url, this._body);

  final Stream<List<int>> _body;

  @override
  http.ByteStream finalize() {
    super.finalize();

    return http.ByteStream(_body);
  }
}
