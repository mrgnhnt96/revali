---
title: Response Headers
description: Headers Revali sets automatically, and setting your own with @SetHeader or the Headers object
---

Revali sets content headers (`Content-Type`, `Content-Length`, ...) from the response body. Add your own with `@SetHeader(name, value)` when the value is fixed, or through the response `Headers` object when it is computed per request.

## Minimal example

<CodeFile name="routes/controllers/data_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('data')
class DataController {
  const DataController();

  @SetHeader('Cache-Control', 'max-age=3600')
  @Get()
  String cached() => 'cached';

  @Get('traced')
  String traced(Headers headers) {
    headers.set('X-Trace-Id', 'abc123');
    return 'traced';
  }
}
```

</CodeFile>

```bash
curl -i http://localhost:8080/api/data
# cache-control: max-age=3600
# content-type: application/json
# {"data":"cached"}

curl -i http://localhost:8080/api/data/traced
# x-trace-id: abc123
# {"data":"traced"}
```

## Automatic headers

| Header | Set when |
| ------ | -------- |
| `Content-Type` | Always, from the body: `application/json`, `text/plain` (`StringContent`), `application/octet-stream` (bytes, streams), the file's type for `File`, the given type for `MemoryFile`. See [Response](/constructs/revali_server/response#return-types). |
| `Content-Length` | Body length when known. Otherwise the response is sent with `Transfer-Encoding: chunked`. |
| `Content-Disposition` | `attachment; filename="..."` for `File` and `MemoryFile` bodies. |
| `Last-Modified`, `Accept-Ranges` | `File` bodies. |
| `Date` | Always, unless you set it. |
| `Content-Encoding`, `Vary` | When [compression](/revali/app-configuration/compression) applies. |
| `Access-Control-*`, `Allow` | CORS headers ([Access control](/constructs/revali_server/access-control/allow-origins)). |

## Setting headers

| Method | Scope | Use when |
| ------ | ----- | -------- |
| `@SetHeader(name, value)` | App class, controller class, or endpoint method | The value is constant. |
| `Headers` / `ResponseHeaders` endpoint parameter | One endpoint | The value is computed in the handler. |
| `response.headers` in a lifecycle component | Wherever the component is applied | The value is computed and shared by many endpoints. |

```dart
class SecurityHeaders implements LifecycleComponent {
  const SecurityHeaders();

  MiddlewareResult apply(Response response) {
    response.headers
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('X-Frame-Options', 'DENY');

    return const MiddlewareResult.next();
  }
}
```

`Headers` methods for writing:

| Method | Effect |
| ------ | ------ |
| `set(name, value, {expose})` / `headers[name] = value` | Replace the header. |
| `add(name, value, {expose})` | Add another value. |
| `remove(name)` | Remove the header. |
| `addAll(map)` | Set several headers. |
| `mimeType`, `contentType`, `contentLength`, `filename`, `lastModified` setters | Typed shortcuts for common headers. |

Header names are case-insensitive.

## Exposing headers to browser JavaScript

Cross-origin `fetch`/XHR code can only read a few response headers unless the others are listed in `Access-Control-Expose-Headers`. Pass `expose: true` to add the header there too:

```dart
@Get('item')
String item(Headers headers) {
  headers.set('X-Request-Id', 'req-1', expose: true);
  return 'ok';
}
```

The response then carries `X-Request-Id: req-1` and `Access-Control-Expose-Headers: X-Request-Id`.

| Call | Effect on `Access-Control-Expose-Headers` |
| ---- | ----------------------------------------- |
| `set(name, value, expose: true)` | Adds `name`. |
| `set(name, value, expose: false)` | Removes `name` (the header value is still set). |
| `set(name, value)` | Unchanged. |
| `expose(name)` / `unexpose(name)` | Add / remove without touching the value. |

`@SetHeader` has no `expose` option; use the `Headers` object.

Related: [Cookies](/constructs/revali_server/response/cookies) · [Status code](/constructs/revali_server/response/status-code) · [Request headers](/constructs/revali_server/request#headers)
