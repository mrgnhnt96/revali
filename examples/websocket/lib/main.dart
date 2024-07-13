// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // _websocket();
  _post();
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
  final dio = Dio()..options.baseUrl = 'http://localhost:8080/api';
  try {
    // stdin to send messages to the server.
    final input = stdin.transform(utf8.decoder).transform(LineSplitter());
    final uri = Uri.parse('/user/123?name=morgan');

    final response = await dio.get(uri.toString());
    print(response.data);

    await for (final line in input) {
      final data = utf8.encode(
        jsonEncode({
          'name': line,
        }),
      );

      final response = await dio.get(
        uri.toString(),
        data: data,
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        ),
      );

      print(response.data);
    }
  } catch (e) {
    print(e);
  }
}
