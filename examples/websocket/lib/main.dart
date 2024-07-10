import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // _websocket();
  _post();
}

Future<void> _websocket() async {
  try {
    // Connect to the remote WebSocket endpoint.
    final uri = Uri.parse('ws://localhost:1234');
    final channel = WebSocketChannel.connect(uri);

    channel.sink.add('hello');

    // Subscribe to messages from the server.
    final sub = channel.stream.listen((message) {
      print(message);
    });

    await sub.asFuture();
  } catch (e) {
    print(e);
  }
}

Future<void> _post() async {
  try {
    final uri = Uri.parse('http://localhost:1234');
    final request = await HttpClient().postUrl(uri);
    // set body to {"message": "Hello, World!"}
    request.write('{"message": "Hello, World!"}');

    final response = await request.close();
    final body = await response.join();
    print(body);
  } catch (e) {
    print(e);
  }
}
