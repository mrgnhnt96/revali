// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  _websocket();
  // _post();
}

Future<void> _websocket() async {
  try {
    // Connect to the remote WebSocket endpoint.
    final uri = Uri.parse('ws://localhost:8080/api/user/create?name=John');
    final channel = WebSocketChannel.connect(uri);

    // Subscribe to messages from the server.
    channel.stream.listen((message) {
      final decoded = jsonDecode(utf8.decode(message));
      print('SERVER: $decoded');
    }, onError: (e) {
      print(e);
    });

    // stdin to send messages to the server.
    final input = stdin.transform(utf8.decoder).transform(LineSplitter());

    await for (final line in input) {
      final data = utf8.encode(
        jsonEncode({
          'message': line,
        }),
      );
      channel.sink.add(data);
    }
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
    final body = await response.transform(utf8.decoder).join();
    print(body);
  } catch (e) {
    print(e);
  }
}
