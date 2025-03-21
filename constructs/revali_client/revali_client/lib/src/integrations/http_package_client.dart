import 'package:http/http.dart' as http;
import 'package:revali_client/src/http_client.dart';
import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

class HttpPackageClient implements HttpClient {
  HttpPackageClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // ignore: unnecessary_await_in_return
    final httpRequest = http.Request(request.method, request.url);

    httpRequest.headers.addAll(request.headers);

    if (request.bodyBytes case final bytes?) {
      httpRequest.bodyBytes = bytes;
    }

    if (request.body case final body?) {
      httpRequest.body = body;
    }

    if (request.encoding case final encoding?) {
      httpRequest.encoding = encoding;
    }

    if (request.contentLength case final contentLength?) {
      httpRequest.contentLength = contentLength;
    }

    final response = await _client.send(httpRequest);

    return HttpResponse(
      request: request,
      statusCode: response.statusCode,
      headers: response.headers,
      stream: response.stream,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      contentLength: response.contentLength,
    );
  }
}
