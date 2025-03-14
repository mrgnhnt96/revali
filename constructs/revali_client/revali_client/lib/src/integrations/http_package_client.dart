import 'package:http/http.dart' as http;
import 'package:revali_client/src/http_client.dart';

class HttpPackageClient implements HttpClient {
  HttpPackageClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.Request request) async {
    // ignore: unnecessary_await_in_return
    return await _client.send(request);
  }
}
