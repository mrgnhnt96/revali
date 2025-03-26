---
description: Two-way communication between a client and a server
---

# WebSockets

WebSockets allow two-way communication between a client and a server, enabling both to send messages at any time. Unlike HTTP, which is request-response based, support real-time data exchange.

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
Learn more about [binding] parameters.
:::

### Two-Way Communication

By default, the WebSocket connection is two-way. This means that the client can send messages to the server and the server can send messages to the client.

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

Closing a connection to the WebSocket can be done in a few ways. It depends on type of Web Socket you are using.

### Send Only

As soon as your handler is resolved, the connection will be closed.

```dart
@WebSocket('websocket', mode: WebSocketMode.sendOnly)
String sendOnly() {
    return 'Hello World'; // Returning a value will close the connection
}
```

### Two Way or Receive Only

Since we are receiving messages from the client, the connection will stay open until the client closes the connection or until you manually close the connection.

```dart
@WebSocket('websocket', mode: WebSocketMode.twoWay)
String twoWay() {
    return 'Hello World'; // Does not close the connection
}
```

The example above will not close the connection, because the handler is going to be called again when a new message is received from the client. To close the connection, you will need to add a `CloseWebSocket` parameter to your handler.

```dart
@WebSocket('websocket', mode: WebSocketMode.twoWay)
String twoWay(CloseWebSocket closer) {
    if (...) {
        closer.close(1000, 'Normal Closure');
        return;
    }

    return 'Hello World'; // Does not close the connection
}
```

Once the `CloseWebSocket.close` is called, any remaining messages will be processed and sent to the client. After the messages are sent, the connection will be closed.

---

The `CloseWebSocket.close` method accepts a `code` and a `reason` argument. The `code` is the status code of the close event, and carries the same principles as a normal `HTTP` status code. The difference is that the codes are in the range of `1000` to `4999`. The `reason` is the reason for closing the connection, and is a string that is limited to 125 bytes (Which is 125 characters in UTF-8).

:::tip
Learn more about [websocket error codes][web-socket-error-codes].
:::

:::danger
The `reason` will be truncated if it is longer than 125 bytes.
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

## Ping

The server can send a ping message to the client to check if the connection is still alive. The client will respond with a pong message. If the client does not respond with a pong message, the server will close the connection.

```dart
@WebSocket.ping('websocket', ping: Duration(seconds: 5))
```

## On Connect

Optionally, you can tell the server to run your handler when the connection is established. This is useful for any setup that needs to be done when the connection is first established.

```dart
@WebSocket('websocket', triggerOnConnect: true)
```

:::caution
When the connection is established, there is no message sent from the client. If you have a `Body` binding on a parameter in your handler, be sure to allow `null` types.

```dart
@WebSocket('websocket', triggerOnConnect: true)
String onConnect(@Body() String? message) {
    return 'Hello World';
}
```

:::

## WebSocket Lifecycle

The WebSocket lifecycle is similar to the [HTTP lifecycle][lifecycle-order], however, there are some differences. The WebSocket lifecycle is as follows:

1. Open Connection
1. Observer
1. Middleware
1. Guard\
   -- On Connect --\
   -- Message Loop --
1. Observer
1. Close Connection

### Message Loop

The message loop is the part of the lifecycle where the server listens for messages from the client. The server will call the handler method when a message is received.

1. Interceptor (Pre)
1. Endpoint
1. Interceptor (Post)

:::note
On Connect is the same as the message loop, but is only run once, when the connection is established.
:::

[binding]: ../core/binding.md
[web-socket-error-codes]: https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
[lifecycle-order]: ../lifecycle-components/overview.md#lifecycle-order
