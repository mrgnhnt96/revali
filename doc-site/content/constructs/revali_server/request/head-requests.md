---
title: HEAD Requests
description: HEAD is answered automatically for every GET route
---

A `HEAD` request asks for the headers a `GET` would return, without the body. Revali answers `HEAD` automatically for every `GET` route, so you normally write nothing.

## Automatic handling

```bash
curl -I http://localhost:8080/api/users
# HTTP/1.1 200 OK
```

For a `HEAD` request that matches a `GET` route, Revali runs the lifecycle (observers, middleware, guards, interceptors) but **does not call the endpoint handler**. The response carries the status and headers those components set, and no body.

Because the handler is skipped, headers derived from the handler's return value, such as the real body's `Content-Type` and `Content-Length`, are not present.

## `@Head`

`@Head([path])` declares a `HEAD` endpoint explicitly. Its handler runs like any other endpoint; set headers through the implied `Headers` parameter. Any body is dropped.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('exports')
class ExportsController {
  const ExportsController();

  @Head('latest')
  void latest(Headers headers) {
    headers.set('X-Export-Version', '42');
  }
}
```

When a `@Head` route and a `@Get` route share a path, the `@Head` route answers `HEAD` requests and the `@Get` route answers `GET`, whichever is declared first. The automatic handling applies only to `GET` routes with no `@Head` on the same path.

`GET` routes also list `HEAD` in the `Allow` header of [OPTIONS](/constructs/revali_server/request/options-requests) responses.
