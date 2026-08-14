---
title: Resilience
description: Timeouts, retries and interceptors for Revali Client
---

<!-- cspell:words idempotent idempotency backoff unparsable undrained -->

A generated client talks to a real network, and real networks fail in ways that a
type-safe method signature cannot describe. A peer accepts the connection and then
never answers. A load balancer returns `503` for four seconds while it drains a node.
An auth interceptor cannot refresh a token and quietly lets the request go out
unauthenticated.

`RevaliClient` gives you three controls for those cases — `timeout`, `retry` and
`interceptors`. All three are deliberately conservative: none of them changes what your
calls do until you ask for it, because a client that silently sends things twice is far
worse than one that fails honestly.

<Callout type="important">

`RevaliClient.timeout` and `RevaliClient.retry` are new in `revali_client` **3.0.0**,
alongside a **breaking change** to `HttpInterceptor`. See
[Migrating to 3.0.0](#migrating-to-300).

</Callout>

---

## Timeouts

By default `RevaliClient` waits forever. That is the behavior it has always had, and it
is a poor default in anything that talks to more than one service: a peer that accepts
connections and never replies holds your request — and whatever is waiting on it —
indefinitely. There is no error to catch, because nothing failed. It just never
finishes.

Set `timeout` to put a bound on that:

```dart
import 'package:revali_client/revali_client.dart';

final client = RevaliClient(
  storage: SessionStorage(),
  baseUrl: 'https://api.example.com',
  timeout: const Duration(seconds: 10),
);
```

Exceeding it throws a `TimeoutException`.

### What the timeout actually covers

This is the part worth reading twice. The deadline covers **reaching the far side and
getting its status line and headers back** — not the time spent streaming the response
body afterwards.

That split is intentional. A slow download and a peer that never answers are different
failures, and holding both to the same deadline would break every long transfer you
have: a ten-second timeout on a two-minute file download is not a safety net, it is a
bug. What you want bounded is the part where you learn whether the peer is alive at
all.

<Callout type="note">

If you need a ceiling on the whole transfer, including the body, apply your own
`.timeout()` to the code that drains `response.stream`. The client deliberately does not
guess at what a reasonable download duration is for you.

</Callout>

### Timeouts and retries together

The timeout applies to **each attempt**, not to the retry sequence as a whole. With
`maxAttempts: 3` and a ten-second timeout, a completely unresponsive peer can occupy
roughly thirty seconds plus backoff before the call gives up. Size the two together.

A `TimeoutException` also counts as a transport failure for retry purposes, so an
idempotent request under a policy with `retryOnConnectionErrors: true` (the default)
will be sent again after one.

---

## Retries

Retrying is **off by default** — `RetryPolicy.none()`. That is not timidity, it is the
only honest default: the client cannot tell from the outside which of your calls
tolerate being sent twice, and getting that wrong charges a customer's card twice.

Turn it on by passing a policy:

```dart
final client = RevaliClient(
  storage: SessionStorage(),
  baseUrl: 'https://api.example.com',
  timeout: const Duration(seconds: 10),
  retry: const RetryPolicy(),
);
```

Once enabled, two rules keep it safe.

### Rule 1 — only idempotent methods

HTTP defines `GET`, `HEAD`, `OPTIONS`, `PUT` and `DELETE` as idempotent: sending one
twice leaves the server in the same state as sending it once. `POST` and `PATCH` are
**not**, and are never retried by the default policy.

The failure this prevents is specific and nasty. A `POST` that reaches the server,
creates a resource, and then fails on the way back — a dropped connection, a proxy
timing out — looks identical to a `POST` that never arrived. Retrying it creates the
resource twice, and nothing in the client can tell the two apart.

That is also why the rule applies to connection errors and not just status codes. A
transport failure includes requests that may well have reached the server, so retrying
one is still gated on the method being idempotent.

The method check is case-insensitive, so `'get'` and `'GET'` behave the same.

### Rule 2 — only transient statuses

Only `502`, `503` and `504` are retried. Those say the far side was temporarily unable
to answer — a gateway with no healthy upstream, a service restarting, an upstream that
took too long.

A `400` or a `404` will say exactly the same thing next time. Retrying it cannot
succeed, and doing it during an incident just multiplies load on a system that is
already struggling. `500` is excluded for the same reason: it usually means the peer
genuinely broke on your input, not that it was briefly unavailable.

### A streamed body is never retried

If the request carries a `bodyStream`, it is refused for retry **regardless of method**
— even a `PUT`.

A stream is consumed as it is sent. By the time the first attempt fails, the bytes are
gone; a second attempt would transmit an empty body and write the wrong thing to the
server, which is worse than the error you were trying to recover from. Buffer the body
into a `List<int>` or a `String` if you want that request retried.

### Backoff and `Retry-After`

Delay doubles from `initialDelay` and is capped at `maxDelay` — 200ms, 400ms, 800ms,
and so on up to ten seconds by default.

When the response carries a `Retry-After` header, it overrides the curve. A server that
tells you when it will be ready knows better than a fixed guess, and honoring it is
what keeps a fleet of clients from stampeding the moment a service comes back.

Only the **delta-seconds** form (`Retry-After: 7`) is honored. The HTTP-date form
(`Retry-After: Wed, 21 Oct 2015 07:28:00 GMT`) is deliberately **ignored** in favor of
the normal backoff — reading it means subtracting the server's clock from yours, and
those two do not reliably agree. A guess that is wrong by a clock skew is worse than a
backoff that is merely approximate. Anything else unparsable, including a negative
value, falls back to the curve as well.

<Callout type="caution">

A honored `Retry-After` is **not** capped by `maxDelay`. A peer answering
`Retry-After: 300` will make the client wait five minutes. If you cannot tolerate that,
set `honorRetryAfter: false` and keep the bounded curve.

</Callout>

### Discarded responses are drained

When a response is thrown away to retry it, the client drains its stream first. An
undrained response still owns its socket, so a retry loop that skipped this would leak
one connection per attempt — the failure mode where turning retries on to survive an
outage is what exhausts your connection pool during it.

### Policy options

| Option | Default | What it does |
| --- | --- | --- |
| `maxAttempts` | `3` | Total attempts including the first. `3` means one try and two retries. Must be `>= 1`. |
| `initialDelay` | `200ms` | Delay before the second attempt; doubles each time. |
| `maxDelay` | `10s` | Ceiling on the computed backoff. |
| `retryableStatusCodes` | `{502, 503, 504}` | Statuses worth sending again. |
| `idempotentMethods` | `{GET, HEAD, OPTIONS, PUT, DELETE}` | Methods safe to send more than once. |
| `retryOnConnectionErrors` | `true` | Whether a transport failure — refused, reset, timed out — is retried. Still gated on the method. |
| `honorRetryAfter` | `true` | Whether a `Retry-After` delta-seconds value overrides the backoff. |

`RetryPolicy.none()` — the default — sets `maxAttempts: 1` and empties every set, so
nothing is ever retried.

Narrowing the policy is straightforward:

```dart
// Read-only calls, quick backoff, ignore whatever the server suggests.
const policy = RetryPolicy(
  maxAttempts: 4,
  initialDelay: Duration(milliseconds: 50),
  maxDelay: Duration(seconds: 2),
  idempotentMethods: {'GET', 'HEAD'},
  honorRetryAfter: false,
);
```

<Callout type="warning">

You *can* add `'POST'` to `idempotentMethods`. Only do it if the endpoint accepts an
idempotency key or is genuinely safe to repeat — the framework has no way to check that
for you, which is the whole reason the default excludes it.

</Callout>

### Where retry and timeout live

Both are implemented in `RevaliClient`, wrapping the transport, rather than inside
`HttpPackageClient`. That means a custom `HttpClient` — a test double, an adapter for a
different HTTP package, a platform-specific implementation — gets both behaviors for
free instead of having to reimplement them, and gets them identically.

The practical consequence to keep in mind: interceptors live *below* the retry loop, so
they run once per attempt, not once per call. An interceptor that stamps a request ID
will produce a new one for each retry.

---

## Configuring a generated client

`timeout` and `retry` are constructor arguments on `RevaliClient`. The generated
`Server` class currently accepts only `client`, `storage`, `baseUrl` (and `websocket`
when your API has sockets), so it does not forward them.

To configure them today, build your own `RevaliClient` and hand it to the generated data
source implementations, which take one directly:

```dart
import 'package:revali_client/revali_client.dart';
import 'package:my_app_client/client.dart';

final storage = SessionStorage();

final client = RevaliClient(
  storage: storage,
  baseUrl: 'https://api.example.com',
  timeout: const Duration(seconds: 10),
  retry: const RetryPolicy(),
);

final users = UserDataSourceImpl(client: client, storage: storage);
```

For headers and other per-request concerns, keep using `Server` and register
interceptors on it — those *are* wired through.

---

## Interceptors

An `HttpInterceptor` observes and rewrites requests on their way out and responses on
the way back. Both hooks can **replace** what they are given:

```dart
abstract interface class HttpInterceptor {
  FutureOr<HttpResponse?> onRequest(HttpRequest request);
  FutureOr<HttpResponse?> onResponse(HttpResponse response);
}
```

Returning `null` — the common case — means "carry on with what you were given".

### Short-circuiting a request

Returning a response from `onRequest` answers the call **without sending anything**.
Nothing touches the network, later interceptors are skipped, and the `onResponse` chain
does not run.

This is what makes an offline cache possible at all:

```dart
class Offline implements HttpInterceptor {
  const Offline(this.cached);

  final Map<Uri, HttpResponse> cached;

  @override
  HttpResponse? onRequest(HttpRequest request) => cached[request.url];

  @override
  HttpResponse? onResponse(HttpResponse response) => null;
}
```

Returning a response from `onResponse` substitutes it for the one that arrived — the
next interceptor in the chain sees your replacement, not the original.

### Mutating instead of replacing

Most interceptors do not need to replace anything; they mutate the `HttpRequest` they
are handed and return `null`. Header injection is the canonical case:

```dart
class AuthInterceptor implements HttpInterceptor {
  const AuthInterceptor(this.storage);

  final Storage storage;

  @override
  Future<HttpResponse?> onRequest(HttpRequest request) async {
    if (await storage['auth_token'] case final String token) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    return null;
  }

  @override
  HttpResponse? onResponse(HttpResponse response) => null;
}
```

The outgoing request is built *after* every interceptor has run, so one that rewrites
the body, the encoding or the content length is reflected in what actually goes on the
wire — not just its headers.

### Errors are not caught

An interceptor that throws now **fails the request**, and the error propagates to your
call site.

The alternative is worse than it sounds. Swallowing the error lets the request continue
in whatever half-prepared state the interceptor left it in — the auth interceptor above,
failing to read its token, would put an unauthenticated request on the wire and surface
as a puzzling `401` from a peer that is behaving perfectly. The error now lands at the
point that actually broke.

If a failure in your interceptor should not fail the request, catch it there and return
`null`. That decision belongs to the interceptor, which knows whether its work was
optional; the framework does not.

### Ordering

Interceptors run in registration order for requests **and** for responses:

```dart
final httpClient = HttpPackageClient(
  interceptors: [
    LoggingInterceptor(),     // 1st on the way out, 1st on the way back
    AuthInterceptor(storage), // 2nd on the way out, 2nd on the way back
  ],
);
```

Put interceptors that modify a request before the ones that only observe it, so what
you log is what is actually sent.

### `HeaderInterceptor`

`HeaderInterceptor` ships with the package and covers the common case of headers that
must be computed **per request** rather than fixed when the client is built:

```dart
final client = Server(
  client: HttpPackageClient(
    interceptors: [
      HeaderInterceptor(
        () => TraceContext.current?.outboundHeaders() ?? const {},
      ),
    ],
  ),
);
```

The motivating case is trace correlation. A server handling a request and calling a peer
should forward its trace headers, but those differ for every request, so they cannot be
baked in at construction. The callback runs once per request, just before it is sent.

It uses `putIfAbsent`, so it never clobbers a header the call site set explicitly — an
ambient default losing to an explicit argument is what callers expect, and the reverse
is very hard to debug.

<Callout type="note">

The callback is deliberately how this is wired rather than a direct dependency on a
trace type. `revali_client` runs on the web, where `dart:io` — and so `revali_core` —
cannot follow, so a plain `Map<String, String> Function()` couples the two without
dragging a server-only dependency into a browser bundle.

</Callout>

---

## Migrating to 3.0.0

Two breaking changes, both in `HttpInterceptor`.

### 1. The hooks return `FutureOr<HttpResponse?>`

`onRequest` and `onResponse` previously returned `void`. That signature made retries,
caching and circuit breaking impossible to build **at all** — by us or by anyone else —
because an interceptor had no way to answer a request or substitute a response. It
changes now rather than after more code depends on it.

The migration is mechanical: change the return type and add `return null`.

```dart
// Before
class LoggingInterceptor implements HttpInterceptor {
  @override
  FutureOr<void> onRequest(HttpRequest request) {
    print('→ ${request.method} ${request.url}');
  }

  @override
  FutureOr<void> onResponse(HttpResponse response) {
    print('← ${response.statusCode}');
  }
}

// After
class LoggingInterceptor implements HttpInterceptor {
  @override
  FutureOr<HttpResponse?> onRequest(HttpRequest request) {
    print('→ ${request.method} ${request.url}');

    return null;
  }

  @override
  FutureOr<HttpResponse?> onResponse(HttpResponse response) {
    print('← ${response.statusCode}');

    return null;
  }
}
```

The analyzer finds every one of these for you — the old signature no longer implements
the interface.

<Callout type="tip">

Interceptors that were declared `void` or `Future<void>` rather than `FutureOr<void>`
migrate the same way: `HttpResponse?` and `Future<HttpResponse?>` both satisfy
`FutureOr<HttpResponse?>`.

</Callout>

### 2. Interceptor errors propagate

Previously a throwing interceptor was swallowed and the request continued. Now it fails
the request.

There is no signature change to make here, but there is a behavior change to check for:
if any of your interceptors relied on being allowed to fail — an optional analytics
call, a best-effort cache write — wrap that work in a `try`/`catch` inside the
interceptor. Anything that was failing silently in production will start surfacing after
this upgrade, which is the point, but it is worth upgrading somewhere you can watch.

---

## What's Next?

- **[Interceptors](/constructs/revali_client/getting-started/http-interceptors)** — the
  full interceptor guide and more patterns
- **[Storage](/constructs/revali_client/getting-started/storage)** — cookies and
  persistent data
- **[Generated Code](/constructs/revali_client/generated-code)** — how the client is
  structured
