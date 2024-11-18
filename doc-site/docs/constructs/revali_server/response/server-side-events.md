# Server Side Events

Server-Sent Events (SSE) is a standard describing how servers can initiate data transmission towards browser clients once an initial client connection has been established. They are commonly used to send real-time updates.

## Creating a Server-Sent Event Handler

Create a Server-Sent Event handler by annotating a method with `@SSE`:

```dart
import 'package:revali_router/revali_router.dart';

@Controller('example')
class MyController {
    const MyController();

    // highlight-next-line
    @SSE('events')
    Stream<String> sendEvents() async* {
        yield 'Hello, world!';
    }
}
```

### Under the Hood

A Server-Sent Event handler is a `GET` method that generally returns a `Stream`. The server will send the data from the stream to the client as a Server-Sent Event. The http connection will remain open until the stream is closed.

### Sending Data

The data sent to the client can be any object that can be converted to a string. Such as a `String`, `Map`, `List`, or a custom object with a `toJson` method.

### Closing the Connection

To close the connection, you can close the stream. The server will automatically close the connection once the stream is closed. If you want to keep the connection open indefinitely, you can return a stream that never closes.

If the connection is closed by the client, the server will automatically close the stream.

## Example

```dart
...
@SSE('events')
Stream<String> sendEvents() async* {
    yield 'Hello, world!';

    await Future<void>.delayed(Duration(seconds: 1));

    yield 'Goodbye, world!';
}
```

In this example, the server will send two messages to the client. The first message is `'Hello, world!'`, and the second message
is `'Goodbye, world!'`. The server will wait for one second between sending the two messages. As soon as the second message is sent, the server will close the connection.

## Listening to Server-Sent Events

Here is an example of how to listen to Server-Sent Events in Dart:

```dart
import 'dart:io';

final http = HttpClient();

final request = await http.getUrl(Uri.parse(url));

final response = await request.close();

final stream = response.asBroadcastStream().transform(utf8.decoder);

await for (final event in stream) {
final data = jsonDecode(event);

print('Received: $data');
}
```
