---
title: WebSockets
description: Two-way messaging over a WebSocket connection with @WebSocket
---

`@WebSocket(path)` upgrades a `GET` request to a WebSocket connection. In the default mode, the endpoint runs once for every message the client sends: `@Body()` binds the incoming message and the return value is sent back. Use it when client and server both send messages; for server-to-client only, [Server-Sent Events](/constructs/revali_server/response/server-sent-events) are simpler.

## Minimal example

<CodeFile name="routes/controllers/chat_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('chat')
class ChatController {
  const ChatController();

  @WebSocket('echo')
  String echo(@Body() String message) => 'echo: $message';
}
```

</CodeFile>

Connect to `ws://localhost:8080/api/chat/echo`:

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:8080/api/chat/echo'),
  );

  channel.stream.listen(print); // {"data":"echo: hi"}
  channel.sink.add('hi');
}
```

## Messages

- **Incoming**: each message is decoded like a request body without a `Content-Type`: JSON if it parses, then url-encoded form (`a=1&b=2`), then number/bool, then string. Bind it with `@Body()` (a class with `fromJson`, `Map<String, dynamic>`, `String`, ...) or a key path such as `@Body(['text'])`.
- **Outgoing**: the return value is encoded like an [HTTP response](/constructs/revali_server/response#return-types): `{"data": ...}` for JSON values, raw text for `StringContent`.
- **Stream returns**: a handler returning `Stream<T>` sends one message per emitted value.
- Other bindings (`@Param`, `@Query`, `@Header`, `@Dep`, ...) read from the upgrade request and work as usual.

## Modes

| Constructor | Mode | Handler runs | Connection closes |
| ----------- | ---- | ------------ | ----------------- |
| `@WebSocket(path)` | `WebSocketMode.twoWay` (default) | On every client message | When the client closes, or the server closes it |
| `@WebSocket(path, mode: WebSocketMode.receiveOnly)` | receive only | On every client message; nothing is sent back | When the client closes, or the server closes it |
| `@WebSocket(path, mode: WebSocketMode.sendOnly)` | send only | Once, on connect | After the handler (or its returned stream) completes |

- `triggerOnConnect: true` also runs the handler once when the connection opens, before any message. `@Body()` is `null` on that call, so make it nullable.
- `@WebSocket.ping(path: 'x', ping: Duration(seconds: 30))` sends ping frames at that interval to keep idle connections alive.
- `@WebSocket.mode(WebSocketMode.sendOnly)` sets the mode with no path.
- In `receiveOnly` mode, return `void`: a returned value closes the connection.

Sending a stream of updates in send-only mode:

```dart
@WebSocket('ticks', mode: WebSocketMode.sendOnly)
Stream<int> ticks() async* {
  for (var i = 1; i <= 3; i++) {
    yield i;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
```

The client receives `{"data":1}`, `{"data":2}`, `{"data":3}`, then the server closes with code `1000`.

## Sending and closing from the handler

Two extra parameter types are implied in WebSocket handlers:

| Type | Use |
| ---- | --- |
| `AsyncWebSocketSender<T>` | `sender.send(value)` sends a message at any time, outside the return value. `T` is the handler's return type with `Future` removed: `String` for `String`/`Future<String>`, `Stream<String>` for `Stream<String>`. |
| `CloseWebSocket` | `close(code, reason)` closes the connection. Reasons longer than 123 bytes are truncated. |

```dart
@WebSocket('commands')
String command(@Body() String command, CloseWebSocket close) {
  if (command == 'bye') {
    close(1000, 'Goodbye');
    return 'closing';
  }
  return 'ok: $command';
}
```

Close codes: `1000` normal, `1001` going away, `1003` unsupported data, `1007` invalid payload (Revali uses it when a message cannot be decoded), `1011` server error (used for uncaught exceptions), `4000`-`4999` application-defined.

## Lifecycle

1. Observers, middleware and guards run once, on the upgrade request. A blocking guard rejects the connection.
2. If `triggerOnConnect` is set, or in `sendOnly` mode, the handler runs once.
3. For each message: pre-interceptors, the handler, then post-interceptors for each message sent back.
4. On close, `CleanUp` callbacks run.
