---
title: Context
description: The per-request object that lifecycle components receive - request, response, shared data, metadata, route, and reflection.
---

`Context` is the per-request object that every [lifecycle component][lifecycle] works with. It gives access to the request, the response being built, data shared between components, metadata from annotations, the matched route, and reflection. Each field can also be requested directly as a method parameter, which is the recommended way to use it.

## Fields

| Field | Type | What it is | Details |
| --- | --- | --- | --- |
| `request` | `Request` | Method, URI, headers, query and path parameters, client IP, and body | [Request][request] |
| `response` | `Response` | Status code, headers, and body of the response being built | [Response][response] |
| `data` | `Data` | Values shared between components and endpoints during this request, keyed by type | [Data Sharing][data-sharing] |
| `meta` | `MetaScope` | Metadata annotations on the endpoint and its controller | [Meta][meta] |
| `route` | `RouteEntry` | The matched route: `path`, `fullPath`, `method`, `parent` | |
| `reflect` | `Reflect` | Metadata on the fields of your return types | [Reflect][reflect] |

The request body is parsed lazily. Before reading `request.body` in a component, call `await request.resolvePayload()`.

## Binding Context Fields

Instead of taking `Context` and reaching into it, declare the pieces you need as parameters. No annotation is needed for these types:

```dart
import 'package:revali_router/revali_router.dart';

class Audit implements LifecycleComponent {
  const Audit();

  // Instead of: MiddlewareResult log(Context context)
  MiddlewareResult log(Request request, RouteEntry route, Data data) {
    print('${request.method} ${route.fullPath}');
    data.add(AuditStarted(DateTime.now()));

    return const MiddlewareResult.next();
  }
}
```

Each field has a matching parameter type: `Request`, `Response`, `Data`, `MetaScope`, `RouteEntry`, and `Reflect`, plus narrower ones such as `RequestHeaders` and `Headers`. The full list is in [Binding: Implied binding][implied].

The same types work in endpoints. For values from the request itself, such as a header, query parameter, or body field, use [binding annotations][binding] like `@Header()` and `@Query()`.

<Callout type="important">

`Headers` is the **response** headers, and setting a value on it changes the response. To read a header the client sent, bind `RequestHeaders` or use `@Header('Name')`.

</Callout>

[lifecycle]: /constructs/revali_server/lifecycle-components
[request]: /constructs/revali_server/request
[response]: /constructs/revali_server/response
[data-sharing]: /constructs/revali_server/context/data-sharing
[meta]: /constructs/revali_server/context/meta
[reflect]: /constructs/revali_server/context/reflect
[binding]: /constructs/revali_server/core/binding
[implied]: /constructs/revali_server/core/binding#implied-binding
