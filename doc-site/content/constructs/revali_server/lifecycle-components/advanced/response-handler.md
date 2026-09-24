---
title: Response Handler
description: Replace how the final response is written to the HTTP connection.
---

A response handler takes the finished `Response` and writes it to the underlying `HttpResponse`: the status, the headers, the transfer encoding, compression, and the body stream. Revali's `DefaultResponseHandler` covers normal HTTP responses, so you only need your own handler when you must control the bytes on the wire yourself.

<Callout type="caution">

A custom handler replaces all of the default behavior for the routes it covers. That includes content-length and chunking, dropping content headers on `204` and `304`, and [compression][compression]. You have to reimplement whatever of that you still need.

</Callout>

## Example

<CodeFile name="lib/components/plain_response_handler.dart">

```dart
import 'dart:io';

import 'package:revali_router/revali_router.dart';

class PlainResponseHandler implements ResponseHandler {
  const PlainResponseHandler();

  @override
  Future<void> handle(
    Response response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    httpResponse.statusCode = response.statusCode;
    // write headers and body to httpResponse...
    await httpResponse.close();
  }
}
```

</CodeFile>

Apply it as an annotation on the app, a controller, or an endpoint:

```dart
@PlainResponseHandler()
@App()
final class MyApp extends AppConfig {
  // ...
}
```

## Scoping

- Only **one** response handler can be applied per app, controller, or endpoint.
- The handler closest to the endpoint wins: endpoint, then controller, then app, then `DefaultResponseHandler`.
- [WebSocket][websockets] and [server-sent event][sse] routes use their own built-in handlers, so a handler set on the app or controller does not apply to them.

[compression]: /revali/app-configuration/compression
[websockets]: /constructs/revali_server/response/websockets
[sse]: /constructs/revali_server/response/server-sent-events
