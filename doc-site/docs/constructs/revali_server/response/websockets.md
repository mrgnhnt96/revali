# Web Sockets

WebSockets allow two-way communication between a client and a server, enabling both to send messages at any time. Unlike HTTP, which is request-response based, WebSockets support real-time data exchange.

## Creating a WebSocket Handler

Create a WebSocket handler by annotating a method with `@WebSocket`:

```dart
import 'package:revali_router/revali_router.dart';

@Controller('example')
class MyController {
    const MyController();

    // highlight-next-line
    @WebSocket('websocket')
    String echoMessage(@Body() String message) {
        return 'Echo: $message';
    }
}
```

:::note
If you're running the server locally, you can connect to the WebSocket via `ws://localhost:8080/example/websocket`.
:::

Every time a message is sent to the WebSocket, the handler (`echoMessage`) will be called. If you're expecting a message sent from the client, you can bind the message using the `@Body` annotation. The headers sent by the client to connect to the WebSocket will remain the same throughout the connection.

:::tip
Learn more about [binding](../core/binding) parameters.
:::

### Two-Way Communication

By default, the Web Socket connection is two-way. This means that the client can send messages to the server and the server can send messages to the client.

```dart
@WebSocket('websocket', mode: WebSocketMode.twoWay)
```

### Receive-Only Communication

If you only want the server to receive messages from the client, you can set the mode to `WebSocketMode.receiveOnly`.

```dart
@WebSocket('websocket', mode: WebSocketMode.receiveOnly)
```

### Send-Only Communication

If you only want the server to send messages to the client, you can set the mode to `WebSocketMode.sendOnly`.

```dart
@WebSocket('websocket', mode: WebSocketMode.sendOnly)
```

## Closing the Connection

To close the connection, throw a `CloseWebSocketException` exception. The exception can be thrown with a status code and a reason. This exception will be automatically handled by the server, and the connection will be closed.

:::note
The `CloseWebSocketException` cannot be caught using [Exception Catchers](../lifecycle-components/exception-catchers)
:::

```dart
import 'package:revali_router/revali_router.dart';

@Controller('example')
class MyController {
    const MyController();

    @WebSocket('websocket')
    String echoMessage() {
        // highlight-start
        if (...) {
            throw CloseWebSocketException(1000, 'Connection closed by client');
        }
        // highlight-end

        return 'Hello World';
    }
}
```

:::tip
Learn more about web socket error codes [here](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code).
:::

:::danger
The reason can be a maximum of 125 bytes (Which is 125 characters in UTF-8).
:::

## Connecting to the WebSocket

There are packages that will help you connect to Web Sockets. For example, you can use the `web_socket_channel` package to connect to a WebSocket.

```dart
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

void main() {
    final uri = Uri.parse('ws://localhost:8080/example/websocket');

    // Connect to the remote WebSocket endpoint.
    final channel = IOWebSocketChannel.connect(
        uri.toString(),
        headers: {
            Headers.contentEncodingHeader: 'utf-8',
            Headers.contentTypeHeader: 'application/json',
        },
    );

    // Subscribe to messages from the server.
    channel.stream.listen(
        (message) {
            final decoded = switch (message) {
            String() => message,
            List<int>() => utf8.decode(List<int>.from(message)),
            _ => throw UnsupportedError(
                'Unsupported message type: ${message.runtimeType}',
                ),
            };

            print('SERVER: $decoded');
        },
        onError: (dynamic e) {
            print('Error $e');
        },
        onDone: () async {
            print('Connection closed');
            print('  code: ${channel.closeCode}');
            print('  reason: ${channel.closeReason}');
        },
    );

    final message = utf8.encode(jsonEncode({'message': 'Hello World'}));
    channel.sink.add(message);
}
```

:::important 🚧 Under Construction 🚧

- Move this to the revali core section

Topics to cover:

- lifecycle of the web socket
- ping constructor
- on connect
:::
