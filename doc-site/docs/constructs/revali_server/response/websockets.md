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
Learn more about [binding] parameters.
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
The `CloseWebSocketException` cannot be caught using [Exception Catchers][exception-catchers]
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
Learn more about [web socket error codes][web-socket-error-codes].
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

## Web Socket Lifecycle

The Web Socket lifecycle is similar to the [HTTP lifecycle][lifecycle-order], however, there are some differences. The Web Socket lifecycle is as follows:

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
[exception-catchers]: ../lifecycle-components/exception-catchers.md
[web-socket-error-codes]: https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
[lifecycle-order]:../lifecycle-components/overview.md#lifecycle-order
