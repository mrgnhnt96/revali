---
title: Server-Sent Events
description: Stream values to the client over a long-lived HTTP response with @SSE
---

`@SSE([path])` declares a `GET` endpoint whose response stays open while the server writes values to it. Return a `Stream`: each emitted value is sent to the client as soon as it is produced, and the response ends when the stream ends or the client disconnects. Use it for one-way server-to-client updates; use [WebSockets](/constructs/revali_server/response/websockets) when the client also needs to send messages.

## Minimal example

<CodeFile name="routes/controllers/ticker_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('ticker')
class TickerController {
  const TickerController();

  @SSE()
  Stream<int> ticks() async* {
    for (var i = 1; i <= 3; i++) {
      yield i;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}
```

</CodeFile>

```bash
curl -N http://localhost:8080/api/ticker
# {"data":1}{"data":2}{"data":3}
```

## Wire format

- Each emitted value is written as one HTTP chunk (`Transfer-Encoding: chunked`) and flushed immediately.
- Values are encoded like [normal responses](/constructs/revali_server/response#return-types): JSON values as `{"data": ...}`, `StringContent` as raw text, custom classes through `toJson()`.
- There is **no** `text/event-stream` framing (`data:` lines, event IDs). The browser `EventSource` API does not parse these responses; read the response body as a stream instead (`fetch` + `ReadableStream`, or `HttpClient` in Dart).
- Returning a `Future<T>` instead of a `Stream` sends one value and closes.

Reading it from Dart:

```dart
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('http://localhost:8080/api/ticker'));
  final response = await request.close();

  await for (final chunk in response.transform(utf8.decoder)) {
    print(chunk); // {"data":1}
  }

  client.close();
}
```

## Cleaning up

To release resources (timers, subscriptions, listeners) when the client disconnects, register a callback with the implied `CleanUp` parameter. Callbacks run when the request closes, for any reason.

```dart
import 'dart:async';

@SSE('clock')
Stream<String> clock(CleanUp cleanUp) {
  final controller = StreamController<String>();
  final timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => controller.add(DateTime.now().toIso8601String()),
  );

  cleanUp.add(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
}
```

## Lifecycle

The lifecycle (middleware, guards, interceptors) runs once per connection, not once per emitted value. An error thrown inside the stream ends the response.
