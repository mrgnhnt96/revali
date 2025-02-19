import 'dart:async';
import 'dart:convert';

import 'package:client_gen_models/client_gen_models.dart';
import 'package:web_socket/web_socket.dart';
import 'package:web_socket_channel/adapter_web_socket_channel.dart';

class Game {
  const Game();

  Stream<String> handle(
    Stream<User> user,
  ) async* {
    final uri = Uri.parse('ws://localhost:1083/api/websocket');

    // Connect to the remote WebSocket endpoint.
    final channel = AdapterWebSocketChannel(
      WebSocket.connect(uri),
    );
    await channel.ready;

    final payloadListener =
        user.map((user) => utf8.encode(jsonEncode(user))).listen(
              channel.sink.add,
              onDone: channel.sink.close,
            );

    // Subscribe to messages from the server.
    yield* channel.stream.map(
      (dynamic e) {
        final json = switch (e) {
          String() => e,
          List<int>() => utf8.decode(List<int>.from(e)),
          _ => throw UnsupportedError(
              'Unsupported message type: ${e.runtimeType}',
            ),
        };

        // parse json
        return json;
      },
    );

    payloadListener.cancel().ignore();
  }
}
