---
title: Request Tracing
description: Correlate one request across every service that handles it
---

A request id that only exists as a header dies at the first hop. The handler
reads `X-Request-Id`, logs it, then calls another service — and that call
arrives as a brand new, uncorrelated request. Both services logged plenty;
neither log can be joined to the other afterwards, so the one question worth
asking of a distributed system — *what happened to this request?* — has no
answer.

Revali carries the correlation identifiers in the zone instead, as
`TraceContext`. Anything running inside the request can reach them without
being handed them: a logger, a repository three layers down, an outbound
client.

```dart
import 'package:revali_core/revali_core.dart';

final id = TraceContext.current?.requestId;
```

You get this by default. There is nothing to enable for the inbound half.

## What is in the context

| Field | What it carries |
| --- | --- |
| `requestId` | Identifies this request across every service that handles it. Always present. |
| `traceparent` | W3C Trace Context `traceparent`, when the caller sent one. |
| `tracestate` | W3C Trace Context `tracestate`, when the caller sent one. |
| `baggage` | A mutable `Map<String, String>` — a tenant, a feature-flag cohort. |

The router seeds the context from what the caller sent, so a request that
arrives already correlated **stays on the same trace** rather than starting its
own. The header names it reads are the ones it also writes back out:
`X-Request-Id`, `traceparent`, `tracestate` and `baggage`.

A blank or absent request id becomes a fresh one — 16 random bytes from a
secure generator, hex encoded — so every request has an id whether or not the
caller supplied one. The context is installed for every request with or without
dependency injection configured: an id that only exists when DI happens to be
set up is one a logger cannot rely on.

`traceparent` is different. It is carried verbatim when present and **never
invented when absent**. A fabricated `traceparent` is worse than none, because
a collector will happily stitch it into the wrong trace — you would be reading
a picture of a request that never happened.

<Callout type="note">

This propagates `traceparent`; it does not create spans. A collector that
already understands W3C Trace Context keeps working, and a service sitting
between two instrumented ones stops breaking the chain — without Revali taking
on span lifetimes, samplers or exporters.

</Callout>

## Reaching the context

`TraceContext.current` is ambient for the whole lifetime of the request,
including across `await`s — a handler that awaits still finds it when it
finally makes its outbound call.

```dart
class OrderService {
  Future<void> place(Order order) async {
    await _repository.save(order);

    // Same context, after an async gap.
    log('placed', requestId: TraceContext.current?.requestId);
  }
}
```

It is `null` outside a request: a background timer, a startup hook, or a
`Router` driven directly without going through the request path. That is why
the type is nullable at every call site — treat the absence as "not in a
request", not as an error.

## Baggage

Baggage is for the values that need to follow a request everywhere but do not
belong in every function signature between here and there. Something early in
the request adds to it; something late — including an outbound call — picks it
up.

```dart
TraceContext.current?.baggage['tenant'] = tenant.id;
```

It **crosses the wire**. Treat it as public to every service you call: no
credentials, no personal data.

Keys and values are percent-encoded on the way out, because an unescaped `,` or
`=` would be read by the next service as a delimiter and silently split one
entry into two. On the way in, an entry that is not `key=value` is skipped
rather than thrown — this is input from another service, and one malformed
entry must not fail the request.

## Crossing to another service

Nothing forwards these headers automatically. `outboundHeaders()` produces what
to send:

```dart
final headers = TraceContext.current?.outboundHeaders() ?? const {};
// {
//   'X-Request-Id': '...',
//   'traceparent': '...',   // only when the caller sent one
//   'tracestate': '...',    // only when the caller sent one
//   'baggage': 'tenant=acme',  // only when baggage is non-empty
// }
```

Only the parts that exist are included — a context with no `traceparent` sends
no `traceparent` key at all, rather than an empty one for the peer to puzzle
over.

The forwarding is one line the app writes because **what counts as a trusted
peer is the app's call, not the framework's**. Correlation headers going to an
arbitrary third party are a small information leak, and the framework has no
way to tell your own billing service from a payment provider's public API.

With a generated [`revali_client`](/constructs/revali_client) client, wire it
once with `HeaderInterceptor`, which computes headers per request instead of
fixing them when the client is built:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:revali_core/revali_core.dart';

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

The callback is deliberately the coupling. `revali_client` runs on the web,
where `dart:io` — and so `revali_core` — cannot follow, so a function returning
`Map<String, String>` connects the two without dragging a server-only
dependency into a browser bundle.

`HeaderInterceptor` never overwrites a header the call site set explicitly: an
ambient default losing to an argument is what a caller expects, and the reverse
is very hard to debug. It also never short-circuits the request — it only
decorates what is already on its way out.

## Crossing to a queue

A message broker is a hop like any other, except the far end may run minutes
later in another process. Publish with the same headers and the correlation
survives the wait:

```dart
await broker.publish(
  'order.placed',
  jsonEncode(order),
  headers: TraceContext.current?.outboundHeaders() ?? const {},
);
```

On the receiving side, `ConsumerRegistry` seeds a `TraceContext` per message
from the message headers, so `TraceContext.current` inside a consumer is the
trace of the request that published the event — not a fresh one:

```dart
await consumers.consume(
  'order.placed',
  group: 'billing',
  onMessage: (message) async {
    // Still the publishing request's trace.
    await invoices.create(message.json);
  },
);
```

## What is deliberately not forwarded

`outboundHeaders()` carries correlation identifiers and nothing else. In
particular, **the caller's `Authorization` header is not forwarded**, and that
omission is a decision rather than an oversight.

Passing a caller's bearer token on to an arbitrary host is a credential leak.
The client has no way to know whether the target is a trusted peer — from
inside the process, a call to your own internal service and a call to a
third-party API look identical. Automatic forwarding would mean that adding an
outbound call to an unrelated vendor silently starts shipping your users'
tokens to it.

If a downstream service genuinely needs the caller's identity, forward it
explicitly at that call site, where the target is known:

```dart
@Get('sync')
Future<void> sync(@Header('Authorization') String authorization) async {
  await http.post(
    // A peer you control, named right here.
    Uri.parse('https://internal.example.com/accounts/sync'),
    headers: {
      ...?TraceContext.current?.outboundHeaders(),
      'Authorization': authorization,
    },
  );
}
```

Better still, exchange the token for one scoped to the peer. Either way it is a
choice made per destination — which is exactly what the framework cannot make
for you.

## Next Steps

- **[Graceful Shutdown](/revali/app-configuration/graceful-shutdown)**: Finish
  in-flight requests before the process exits
- **[Request-Scoped Dependencies](/revali/app-configuration/request-scoped-dependencies)**:
  The other thing that rides the request's zone
- **[HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors)**:
  Where `HeaderInterceptor` plugs in on the client
