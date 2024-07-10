import 'dart:io';

void main() async {
  HttpServer server = await HttpServer.bind('localhost', 1234);
  final requests = server.asBroadcastStream();

  final http = requests.listen(handle);

  print('Server running on http://${server.address.host}:${server.port}');

  await http.asFuture();
}

void onWebSocketData(WebSocket client) {
  client.listen((data) {
    print('received: $data');
    client.add('Echo: $data');
  });
}

void handle(HttpRequest request) {
  if (request.uri.path == '') {
    WebSocketTransformer.upgrade(request).then(onWebSocketData);
  } else {
    onHttpRequest(request);
  }
}

void onHttpRequest(HttpRequest request) async {
  final body = await request.join();
  request.response.write('{ "message": "Hello, World!"}');
  request.response.close();
}
