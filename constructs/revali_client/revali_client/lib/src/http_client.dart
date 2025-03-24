import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

abstract interface class HttpClient {
  const HttpClient();

  Future<HttpResponse> send(HttpRequest request);
}
