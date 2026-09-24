---
title: Request Tracing
description: Read the request id and W3C trace context anywhere in a request, and forward them to other services
---

Every request carries a `TraceContext` that any code running in the request can read, without passing it as a parameter. Use it to put a request id in your logs, and forward it on outbound calls so logs from different services can be matched up. It is always on.

```dart
import 'package:revali_router/revali_router.dart';

final requestId = TraceContext.current?.requestId;
```

`TraceContext.current` stays available across `await`s. Outside a request (at startup, or in a timer) it is `null`.

| Field | Contents |
| --- | --- |
| `requestId` | Taken from the incoming `X-Request-Id` header. If the header is missing or blank, a random 32-character hex id is generated. Always set. |
| `traceparent` | The W3C `traceparent` header, if the caller sent one. It is never generated. |
| `tracestate` | The W3C `tracestate` header, if the caller sent one. |
| `baggage` | A mutable `Map<String, String>` parsed from the `baggage` header. It is sent to every service you forward it to, so keep secrets and personal data out of it. |

Revali forwards `traceparent` but doesn't create spans. Collectors that understand W3C Trace Context keep working.

## Forwarding to Another Service

Revali never forwards these headers on its own. `outboundHeaders()` returns the headers that are set and leaves out the rest:

```dart
final headers = TraceContext.current?.outboundHeaders() ?? const {};
// {'X-Request-Id': '...', 'traceparent': '...', 'tracestate': '...', 'baggage': 'tenant=acme'}
```

With a generated [`revali_client`](/constructs/revali_client), add them to every call with `HeaderInterceptor`. It never overwrites a header that the call itself sets:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:revali_router/revali_router.dart';

final server = Server(
  client: HttpPackageClient(
    interceptors: [
      HeaderInterceptor(
        () => TraceContext.current?.outboundHeaders() ?? const {},
      ),
    ],
  ),
);
```

`outboundHeaders()` never includes the caller's `Authorization` header. If a downstream service needs it, add it yourself at that call, because only you know whether the target is trusted.

## Forwarding Through a Queue

Publish with the same headers. Inside the [consumer](/revali/messaging), `TraceContext.current` is then the context of the request that published the message:

```dart
await broker.publish(
  'order.placed',
  jsonEncode(order),
  headers: TraceContext.current?.outboundHeaders() ?? const {},
);
```
