---
description: Real-time bidirectional communication between client and server
---

# WebSockets

> Annotation: `@WebSocket`

WebSockets enable real-time, bidirectional communication between client and server. Unlike HTTP's request-response pattern, WebSockets allow both sides to send messages at any time.

## Creating a WebSocket Handler

Create a WebSocket handler by annotating a method with `@WebSocket`:

```dart
import 'package:revali_router/revali_router.dart';

@Controller('chat')
class ChatController {
  const ChatController();

  @WebSocket('messages')
  String handleMessage(@Body() String message) {
    return 'Echo: $message';
  }
}
```

:::note
**Connection URL:** If running locally, connect via `ws://localhost:8080/chat/messages`
:::

## WebSocket Modes

### Two-Way Communication (Default)

Both client and server can send messages:

```dart
@WebSocket('messages', mode: WebSocketMode.twoWay)
String handleMessage(@Body() String message) {
  return 'Echo: $message';
}
```

### Receive-Only

Server only receives messages from client:

```dart
@WebSocket('messages', mode: WebSocketMode.receiveOnly)
void handleMessage(@Body() String message) {
  // Process message without sending response
  print('Received: $message');
}
```

### Send-Only

Server only sends messages to client:

```dart
@WebSocket('notifications', mode: WebSocketMode.sendOnly)
String sendNotification() {
  return 'Server notification';
}
```

## Handling Messages

### Basic Message Handling

```dart
@WebSocket('chat')
String handleChatMessage(@Body() String message) {
  // Process the message
  final processedMessage = processMessage(message);

  // Return response to client
  return 'Server: $processedMessage';
}
```

### JSON Messages

```dart
class ChatMessage {
  const ChatMessage({required this.user, required this.text});

  final String user;
  final String text;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      user: json['user'] as String,
      text: json['text'] as String,
    );
  }
}

@WebSocket('chat')
String handleChatMessage(@Body() ChatMessage message) {
  return '${message.user}: ${message.text}';
}
```

### Async Message Handling

```dart
@WebSocket('async')
Future<String> handleAsyncMessage(@Body() String message) async {
  // Simulate async processing
  await Future.delayed(const Duration(seconds: 1));

  return 'Processed: $message';
}
```

## Sending Messages Without Client Input

Use `AsyncWebSocketSender` to send messages without waiting for client input:

```dart
@WebSocket('notifications')
String sendNotifications(AsyncWebSocketSender<String> sender) {
  // Send periodic notifications
  Timer.periodic(const Duration(seconds: 5), (timer) {
    sender.send('Notification ${DateTime.now()}');
  });

  return 'Notifications started';
}
```

:::important
**Type Matching:** The `AsyncWebSocketSender` type parameter must match the return type of your handler:

```dart
String => AsyncWebSocketSender<String>
Future<String> => AsyncWebSocketSender<String>
Stream<String> => AsyncWebSocketSender<Stream<String>>
```

:::

## Connection Management

### Closing Connections

#### Send-Only Mode

Connections close automatically when the handler returns:

```dart
@WebSocket('send-only', mode: WebSocketMode.sendOnly)
String sendData() {
  return 'Final message'; // Connection closes after this
}
```

#### Two-Way and Receive-Only Modes

Connections stay open until manually closed:

```dart
@WebSocket('persistent', mode: WebSocketMode.twoWay)
String handleMessage(CloseWebSocket closer) {
  // Check if connection should close
  if (shouldCloseConnection()) {
    closer.close(1000, 'Normal closure');
    return '';
  }

  return 'Message processed';
}
```

### Close Codes

WebSocket close codes follow HTTP status code principles but use the range 1000-4999:

```dart
// Normal closure
closer.close(1000, 'Normal closure');

// Going away
closer.close(1001, 'Going away');

// Protocol error
closer.close(1002, 'Protocol error');

// Unsupported data
closer.close(1003, 'Unsupported data');

// Custom application codes (4000-4999)
closer.close(4000, 'Custom application error');
```

:::danger
**Reason Length:** The close reason is limited to 125 bytes (125 characters in UTF-8). Longer reasons will be truncated.
:::

## Advanced Features

### Ping/Pong

Enable automatic ping/pong to keep connections alive:

```dart
@WebSocket.ping('heartbeat', ping: Duration(seconds: 30))
String handleHeartbeat(@Body() String? message) {
  return 'Pong: ${DateTime.now()}';
}
```

### On Connect Trigger

Run handler when connection is established:

```dart
@WebSocket('connection', triggerOnConnect: true)
String onConnect(@Body() String? message) {
  if (message == null) {
    return 'Connected to WebSocket';
  }

  return 'Message: $message';
}
```

:::caution
**Null Message Handling:** When `triggerOnConnect: true`, the `@Body()` parameter may be null since no message is sent during connection.
:::

## Real-World Examples

### Chat Application

```dart
@Controller('chat')
class ChatController {
  final List<String> _messages = [];

  @WebSocket('messages')
  String handleMessage(@Body() String message) {
    _messages.add('${DateTime.now()}: $message');

    // Broadcast to all connected clients
    broadcastMessage(message);

    return 'Message received';
  }

  void broadcastMessage(String message) {
    // Implementation depends on your broadcasting strategy
  }
}
```

### Real-Time Notifications

```dart
@Controller('notifications')
class NotificationController {
  @WebSocket('stream', mode: WebSocketMode.sendOnly)
  String streamNotifications(AsyncWebSocketSender<String> sender) {
    // Stream notifications from a service
    notificationService.stream.listen((notification) {
      sender.send(notification.toJson());
    });

    return 'Notification stream started';
  }
}
```

### File Upload Progress

```dart
@Controller('upload')
class UploadController {
  @WebSocket('progress')
  String handleUpload(@Body() Map<String, dynamic> data) {
    final progress = data['progress'] as int;
    final filename = data['filename'] as String;

    if (progress == 100) {
      return 'Upload complete: $filename';
    }

    return 'Upload progress: $progress%';
  }
}
```

## Client Connection

### Using web_socket_channel

```dart
import 'dart:convert';
import 'package:web_socket_channel/io.dart';

void main() {
  final channel = IOWebSocketChannel.connect('ws://localhost:8080/chat/messages');

  // Listen for messages
  channel.stream.listen(
    (message) {
      print('Received: $message');
    },
    onError: (error) {
      print('Error: $error');
    },
    onDone: () {
      print('Connection closed');
    },
  );

  // Send message
  channel.sink.add('Hello WebSocket!');
}
```

### Using dart:io WebSocket

```dart
import 'dart:io';

void main() async {
  final socket = await WebSocket.connect('ws://localhost:8080/chat/messages');

  socket.listen(
    (message) {
      print('Received: $message');
    },
    onError: (error) {
      print('Error: $error');
    },
    onDone: () {
      print('Connection closed');
    },
  );

  socket.add('Hello WebSocket!');
}
```

## WebSocket Lifecycle

The WebSocket lifecycle follows this pattern:

1. **Open Connection** - Client connects
2. **Observer** - Pre-connection observers run
3. **Middleware** - Middleware components run
4. **Guard** - Guard components run
5. **On Connect** - Handler runs if `triggerOnConnect: true`
6. **Message Loop** - For each message:
   - Interceptor (Pre)
   - Endpoint Handler
   - Interceptor (Post)
7. **Observer** - Post-connection observers run
8. **Close Connection** - Connection closes

## Best Practices

### Use Appropriate Modes

```dart
// ✅ Good - Use send-only for notifications
@WebSocket('notifications', mode: WebSocketMode.sendOnly)
String sendNotification() {
  return 'Notification';
}

// ✅ Good - Use receive-only for logging
@WebSocket('logs', mode: WebSocketMode.receiveOnly)
void logMessage(@Body() String message) {
  logger.info(message);
}
```

### Handle Connection Cleanup

```dart
// ✅ Good - Proper cleanup
@WebSocket('data')
String handleData(CloseWebSocket closer, CleanUp cleanUp) {
  cleanUp.add(() {
    // Cleanup resources when connection closes
    resourceService.dispose();
  });

  return 'Data processed';
}
```

### Use Type-Safe Messages

```dart
// ✅ Good - Type-safe message handling
class ChatMessage {
  const ChatMessage({required this.user, required this.text});
  final String user;
  final String text;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      user: json['user'] as String,
      text: json['text'] as String,
    );
  }
}

@WebSocket('chat')
String handleChat(@Body() ChatMessage message) {
  return '${message.user}: ${message.text}';
}
```

## What's Next?

- Learn about [Server-Sent Events](./server-sent-events.md) for one-way streaming
- Explore [response body](./body.md) for HTTP responses
- See [response headers](./headers.md) for HTTP headers
