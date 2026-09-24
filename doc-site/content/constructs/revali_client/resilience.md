---
title: Interceptors, Timeouts & Retries
description: Add headers, logging, caching, timeouts and retries to a revali_client client
---

<!-- cspell:words idempotent idempotency backoff undrained -->

Three hooks shape how the generated client sends requests: **interceptors** (rewrite or answer requests), **`timeout`** and **`retry`** (both on `RevaliClient`). Timeouts and retries are off by default.

## Interceptors

An `HttpInterceptor` sees every request before it is sent and every response after it arrives:

```dart
abstract interface class HttpInterceptor {
  FutureOr<HttpResponse?> onRequest(HttpRequest request);
  FutureOr<HttpResponse?> onResponse(HttpResponse response);
}
```

Mutate the `HttpRequest` and return `null` to carry on. That covers most interceptors, such as auth headers:

<CodeFile name="lib/auth_interceptor.dart">

```dart
import 'package:revali_client/revali_client.dart';

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

</CodeFile>

Register interceptors on the `HttpClient` you pass to `Server`:

```dart
final storage = SessionStorage();

final server = Server(
  storage: storage,
  client: HttpPackageClient(
    interceptors: [AuthInterceptor(storage), const LoggingInterceptor()],
  ),
);

// or, after construction:
server.client.interceptors.add(const LoggingInterceptor());
```

### Rules

- **Order.** Interceptors run in list order, for requests and for responses alike. Put interceptors that change the request before ones that only log it.
- **Replacing a response.** Return an `HttpResponse` from `onResponse` to substitute it. The next interceptor sees your replacement.
- **Answering without the network.** Return an `HttpResponse` from `onRequest` and nothing is sent: later interceptors and the whole `onResponse` chain are skipped. This is how you build an offline cache or a stub.
- **Errors propagate.** An interceptor that throws fails the request, and the error reaches your call site. If the interceptor's work is optional, catch inside it and return `null`.
- **The body is built last.** The outgoing request is assembled after every `onRequest` has run, so changes to `body`, `bodyBytes`, `encoding` or `contentLength` are sent, not just header changes.
- **Once per attempt.** With retries on, interceptors run again for each attempt.

`HttpRequest` has `method`, `url`, mutable `headers`, `body`, `bodyBytes`, `bodyStream`, `encoding` and `contentLength`. `HttpResponse` has `request`, `statusCode`, `headers`, `reasonPhrase`, `contentLength`, `persistentConnection` and the body `stream`.

### `HeaderInterceptor`

For headers that must be computed per request, such as forwarding trace headers from a server to a peer, use the built-in `HeaderInterceptor`. Its callback runs once per request, and it never overwrites a header the call already set:

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

See [Tracing](/revali/app-configuration/tracing) for the server side.

## Timeouts

`RevaliClient.timeout` bounds how long a request waits for the status line and headers. It does not bound streaming the body afterwards, so long downloads are not cut off. Exceeding it throws a `TimeoutException`. It is `null` (wait forever) by default.

The timeout applies to **each attempt**. With `maxAttempts: 3` and a 10 second timeout, an unresponsive peer can hold a call for about 30 seconds plus backoff.

To bound the body download too, add your own `.timeout()` where you read `response.stream`.

## Retries

`RevaliClient.retry` is `RetryPolicy.none()` by default. `const RetryPolicy()` turns on a safe default:

- **Only idempotent methods**: `GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE` (case-insensitive). `POST` and `PATCH` are never retried, because a `POST` that reached the server and then lost its response would create the resource twice.
- **Only transient statuses**: `502`, `503`, `504`. A `400`, `404` or `500` would fail the same way again.
- **Transport failures** (refused, reset, timed out) are retried too, still only for idempotent methods.
- **Streamed bodies are never retried.** A `bodyStream` is consumed by the first attempt. Send a `List<int>` or `String` if the request must be retryable.
- **Backoff** doubles from `initialDelay` up to `maxDelay`: 200 ms, 400 ms, 800 ms and so on, capped at 10 s.
- **`Retry-After`** in delta-seconds form (`Retry-After: 7`) replaces the backoff and is **not** capped by `maxDelay`. The HTTP-date form is ignored. Set `honorRetryAfter: false` to always use the backoff.
- A response that is discarded for a retry is drained first, so retries do not leak connections.

| `RetryPolicy` option | Default | Meaning |
| --- | --- | --- |
| `maxAttempts` | `3` | Total attempts including the first. Must be `>= 1`. |
| `initialDelay` | `200ms` | Delay before the second attempt. Doubles each time. |
| `maxDelay` | `10s` | Cap on the computed backoff. |
| `retryableStatusCodes` | `{502, 503, 504}` | Statuses to retry. |
| `idempotentMethods` | `{GET, HEAD, OPTIONS, PUT, DELETE}` | Methods that may be retried. Add `POST` only for endpoints that are safe to repeat, such as ones that take an idempotency key. |
| `retryOnConnectionErrors` | `true` | Retry transport failures. |
| `honorRetryAfter` | `true` | Let a `Retry-After` delay override the backoff. |

Timeout and retry wrap the transport inside `RevaliClient`, so a custom `HttpClient` gets both without extra work.

## Configuring a generated client

The generated `Server` builds its own `RevaliClient` and accepts only `client`, `storage` and `baseUrl` (plus `websocket`). It does not forward `timeout` or `retry`. To use them, build a `RevaliClient` and pass it to the generated implementations directly:

```dart
import 'package:client/client.dart';
import 'package:revali_client/revali_client.dart';

final storage = SessionStorage();

final client = RevaliClient(
  storage: storage,
  baseUrl: 'https://api.example.com/api',
  client: HttpPackageClient(interceptors: [AuthInterceptor(storage)]),
  timeout: const Duration(seconds: 10),
  retry: const RetryPolicy(),
);

final users = UserDataSourceImpl(client: client, storage: storage);
```

## Migrating to 3.0.0

`revali_client` 3.0.0 made two breaking changes to `HttpInterceptor`:

1. `onRequest` and `onResponse` return `FutureOr<HttpResponse?>` instead of `FutureOr<void>`. Change the return type and add `return null;`. The analyzer flags every interceptor that still uses the old signature.
2. An interceptor that throws now fails the request instead of being swallowed. Wrap optional work, such as analytics, in `try`/`catch` inside the interceptor.

```dart
// Before
@override
FutureOr<void> onRequest(HttpRequest request) {
  print('-> ${request.method} ${request.url}');
}

// After
@override
FutureOr<HttpResponse?> onRequest(HttpRequest request) {
  print('-> ${request.method} ${request.url}');
  return null;
}
```
