---
title: HTTP Methods
description: Method annotations that turn controller methods into endpoints, and the route path syntax
---

A method annotation (`@Get`, `@Post`, ...) turns a controller method into an endpoint for that HTTP method. Its optional path argument is appended to the [controller](/constructs/revali_server/core/controllers) path.

## Minimal example

<CodeFile name="routes/controllers/status_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('status')
class StatusController {
  const StatusController();

  @Get()
  String status() => 'ok';

  @Get('version')
  String version() => '1.2.0';
}
```

</CodeFile>

```bash
curl http://localhost:8080/api/status
# {"data":"ok"}

curl http://localhost:8080/api/status/version
# {"data":"1.2.0"}
```

## Method annotations

| Annotation | HTTP method | Docs |
| ---------- | ----------- | ---- |
| `@Get([path])` | `GET` | |
| `@Post([path])` | `POST` | |
| `@Put([path])` | `PUT` | |
| `@Patch([path])` | `PATCH` | |
| `@Delete([path])` | `DELETE` | |
| `@Head([path])` | `HEAD` | [HEAD requests](/constructs/revali_server/request/head-requests) |
| `@SSE([path])` | `GET`, response kept open and streamed | [Server-Sent Events](/constructs/revali_server/response/server-sent-events) |
| `@WebSocket(path)` | WebSocket (a `GET` upgrade request) | [WebSockets](/constructs/revali_server/response/websockets) |

- One method annotation per method. A second one fails the build.
- The method name is never part of the URL.
- `HEAD` and `OPTIONS` are answered automatically for every route; you rarely need `@Head`. See [HEAD](/constructs/revali_server/request/head-requests) and [OPTIONS](/constructs/revali_server/request/options-requests).

## Path syntax

| Segment | Meaning | Example path | Matches |
| ------- | ------- | ------------ | ------- |
| `name` | Literal segment | `version` | `/api/status/version` |
| `:name` | One dynamic segment, bound with `@Param()` | `:id` | `/api/users/42` |
| `*name` | All remaining segments, bound with `@Param() List<String> name` | `files/*path` | `/api/files/a/b.txt` |

- Do not start or end a path with `/` (`@Get('version')`, not `@Get('/version')`); the router rejects it at startup. Nested paths use inner slashes: `@Get('a/b')`.
- Allowed characters: letters, digits, `-`, `_`, `.`, plus `:` and `*` at the start of a segment.
- Controller paths can contain parameters too: `@Controller('shops/:shopId')` makes `shopId` available to every endpoint in the controller.
- A path parameter is always required. A request missing the segment matches no route and gets `404`.

### Path parameters

```dart
@Controller('shops/:shopId')
class ProductsController {
  const ProductsController();

  @Get('products/:productId')
  Map<String, String> product(
    @Param() String shopId,
    @Param() String productId,
  ) {
    return {'shopId': shopId, 'productId': productId};
  }
}
```

```bash
curl http://localhost:8080/api/shops/abc/products/xyz
# {"data":{"shopId":"abc","productId":"xyz"}}
```

Path parameter values are `String`s. To get another type, transform the value with a [pipe](/constructs/revali_server/core/pipes). Binding details are on the [Binding](/constructs/revali_server/core/binding#param---path-parameters) page.

## Custom HTTP methods

Extend `Method` to serve a verb Revali does not ship an annotation for:

```dart
import 'package:revali_router/revali_router.dart';

final class Purge extends Method {
  const Purge([String? path]) : super('PURGE', path: path);
}

@Controller('cache')
class CacheController {
  const CacheController();

  @Purge()
  String purge() => 'purged';
}
```

```bash
curl -X PURGE http://localhost:8080/api/cache
# {"data":"purged"}
```

Next: [Binding](/constructs/revali_server/core/binding) · [Response](/constructs/revali_server/response)
