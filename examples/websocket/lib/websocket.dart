import 'dart:io';

void main() async {
  final server = await HttpServer.bind('localhost', 1234);
  server.asBroadcastStream().listen(handle);

  print('Server running on http://${server.address.host}:${server.port}');
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

Future<void> onHttpRequest(HttpRequest request) async {
  request.response.write('{ "message": "Hello, World!"}');
  await request.response.close();
}
