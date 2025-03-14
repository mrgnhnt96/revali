import 'package:http/http.dart' as http;

abstract interface class HttpClient {
  const HttpClient();

  Future<http.StreamedResponse> send(http.Request request);
}
