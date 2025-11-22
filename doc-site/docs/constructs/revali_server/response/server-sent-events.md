---
description: Send real-time updates to clients using Server-Sent Events
---

# Server-Sent Events

> Annotation: `@SSE`

Server-Sent Events (SSE) enable servers to push real-time updates to clients over a single HTTP connection. Unlike WebSockets, SSE is one-way communication from server to client.

## Creating an SSE Handler

Create an SSE handler by annotating a method with `@SSE`:

```dart
import 'package:revali_router/revali_router.dart';

@Controller('events')
class EventController {
  const EventController();

  @SSE('updates')
  Stream<String> sendUpdates() async* {
    yield 'Hello, world!';
    yield 'This is a real-time update';
  }
}
```

## Connection Management

### Automatic Cleanup

SSE connections automatically close when the stream ends:

```dart
@SSE('limited')
Stream<String> sendLimitedData() async* {
  for (int i = 0; i < 5; i++) {
    yield 'Update $i';
    await Future.delayed(const Duration(seconds: 1));
  }
  // Connection closes automatically after 5 messages
}
```

### Manual Cleanup

Use `CleanUp` to register cleanup callbacks:

```dart
@SSE('events')
Stream<String> sendEvents(CleanUp cleanUp) async* {
  // Register cleanup callback
  cleanUp.add(() {
    print('Connection closed, cleaning up resources');
    resourceService.dispose();
  });

  // Stream data
  yield* eventService.stream;
}
```

### Infinite Streams

Keep connections open indefinitely:

```dart
@SSE('live')
Stream<String> sendLiveUpdates() async* {
  // This stream never ends, connection stays open
  await for (final update in liveUpdateService.stream) {
    yield update;
  }
}
```

## Client Implementation

### Dart Client

```dart
import 'dart:io';
import 'dart:convert';

void main() async {
  final http = HttpClient();

  try {
    final request = await http.getUrl(Uri.parse('http://localhost:8080/events/updates'));
    final response = await request.close();

    if (response.statusCode == 200) {
      final stream = response.transform(utf8.decoder);

      await for (final event in stream) {
        print('Received: $event');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    http.close();
  }
}
```

## Error Handling

### Connection Errors

```dart
@SSE('events')
Stream<String> sendEvents() async* {
  try {
    yield* eventService.stream;
  } catch (e) {
    yield 'Error: $e';
    // Connection will close after error
  }
}
```

### Graceful Degradation

```dart
@SSE('events')
Stream<String> sendEvents() async* {
  try {
    yield* eventService.stream;
  } catch (e) {
    yield 'Service temporarily unavailable';
    await Future.delayed(const Duration(seconds: 5));

    // Try to reconnect
    yield* sendEvents();
  }
}
```

## Best Practices

### Use Appropriate Data Types

```dart
// ✅ Good - Use objects with toJson for complex data
class StatusUpdate {
  const StatusUpdate({required this.status, required this.timestamp});
  final String status;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

@SSE('status')
Stream<StatusUpdate> sendStatus() async* {
  yield StatusUpdate(status: 'Running', timestamp: DateTime.now());
}

// ❌ Avoid - Complex objects without serialization
class ComplexObject {
  final Function callback;
  final Stream stream;
  // No toJson method
}
```

### Handle Connection Cleanup

```dart
// ✅ Good - Proper cleanup
@SSE('events')
Stream<String> sendEvents(CleanUp cleanUp) async* {
  final subscription = eventService.stream.listen((event) {
    // Handle events
  });

  cleanUp.add(() {
    subscription.cancel();
    resourceService.dispose();
  });

  yield* eventService.stream;
}
```

### Avoid Memory Leaks

```dart
// ✅ Good - Limited duration streams
@SSE('updates')
Stream<String> sendUpdates() async* {
  for (int i = 0; i < 100; i++) {
    yield 'Update $i';
    await Future.delayed(const Duration(seconds: 1));
  }
  // Stream ends, connection closes
}

// ❌ Avoid - Infinite streams without cleanup
@SSE('updates')
Stream<String> sendUpdates() async* {
  while (true) {
    yield 'Update';
    await Future.delayed(const Duration(seconds: 1));
    // No way to stop this stream
  }
}
```

## SSE vs WebSockets

| Feature             | Server-Sent Events          | WebSockets                    |
| ------------------- | --------------------------- | ----------------------------- |
| **Direction**       | Server → Client only        | Bidirectional                 |
| **Protocol**        | HTTP                        | WebSocket                     |
| **Reconnection**    | Automatic                   | Manual                        |
| **Browser Support** | Native                      | Native                        |
| **Use Case**        | Live updates, notifications | Chat, real-time collaboration |

## What's Next?

- Learn about [WebSockets](./websockets.md) for bidirectional communication
- Explore [response body](./body.md) for HTTP responses
- See [response headers](./headers.md) for HTTP headers
