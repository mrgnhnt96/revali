---
title: Request
description: The read-only Request object, its properties, and how to access it from endpoints and lifecycle components
---

`Request` is the incoming HTTP request: method, URI, headers, query and path parameters, body and client IP. It is read-only. In endpoints, prefer [binding annotations](/constructs/revali_server/core/binding) over reading `Request` directly; use `Request` in [lifecycle components](/constructs/revali_server/lifecycle-components) or when you need several raw values at once.

## Accessing the request

| Where | How |
| ----- | --- |
| Endpoint | Add a `Request` parameter (no annotation, see [implied binding](/constructs/revali_server/core/binding#implied-binding)). |
| Lifecycle component method | Add a `Request` parameter, or read `context.request`. |
| Pipe or custom `Bind` | `context.request` |

```dart
import 'package:revali_router/revali_router.dart';

@Controller('debug')
class DebugController {
  const DebugController();

  @Get()
  Map<String, dynamic> describe(Request request) {
    return {
      'method': request.method,
      'path': request.uri.path,
      'query': request.queryParameters,
      'agent': request.headers.get('User-Agent'),
    };
  }
}
```

```bash
curl 'http://localhost:8080/api/debug?page=2' -H 'User-Agent: curl'
# {"data":{"method":"GET","path":"/api/debug","query":{"page":2},"agent":"curl"}}
```

## Properties

| Property | Type | Notes |
| -------- | ---- | ----- |
| `method` | `String` | `GET`, `POST`, ... |
| `uri` | `Uri` | Full request URI. |
| `segments` | `Iterable<String>` | Path segments. |
| `headers` | `Headers` | Request headers (see below). |
| `queryParameters` | `Map<String, dynamic>` | Last value per key, type-coerced (`"2"` becomes `2`). |
| `queryParametersAll` | `Map<String, Iterable<dynamic>>` | Every value per key, type-coerced. |
| `pathParameters` | `Map<String, String>` | Values of `:name` segments. |
| `wildcardParameters` | `Map<String, List<String>>` | Segments captured by `*name`. |
| `ip` | `String?` | Client IP. See [Client IP](/constructs/revali_server/request/client-ip). |
| `body` | `Body` | Decoded body. Call `resolvePayload()` first outside endpoints. See [Request body](/constructs/revali_server/request/body). |
| `originalPayload` | `Payload` | The raw, undecoded payload. |

## Headers

Read a single header with `@Header()` in an endpoint:

```dart
@Get('whoami')
String whoami(@Header('Authorization') String? auth) => auth ?? 'anonymous';
```

To read all of them, take a `RequestHeaders` parameter, or use `context.request.headers` in a lifecycle component:

| Method | Returns |
| ------ | ------- |
| `get(name)` / `headers[name]` | The value, repeated headers joined with `, `; `null` if absent. Names are case-insensitive. |
| `getAll(name)` | Every value as a `List<String>`, or `null`. |
| `keys`, `values`, `forEach` | Iterate all headers. |
| `mimeType`, `contentType`, `contentLength`, `encoding`, `origin`, `range`, `ifModifiedSince` | Parsed common headers. |
| `cookies` | Request cookies. Prefer `@Cookie('name')` in endpoints. |

<Callout type="caution">

An endpoint parameter of type `Headers` is the **response** headers, not the request headers. Use `RequestHeaders` or `@Header()` to read what the client sent.

</Callout>

Related: [Request body](/constructs/revali_server/request/body) · [Client IP](/constructs/revali_server/request/client-ip) · [Response](/constructs/revali_server/response)
