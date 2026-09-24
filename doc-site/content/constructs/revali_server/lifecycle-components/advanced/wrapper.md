---
title: Request Wrapper
description: Wrap the whole request pipeline in setup and teardown code, such as a Zone value, a transaction, or timing.
---

A request wrapper runs code **around** the rest of the pipeline. It does its setup, calls `next()` to run middleware, guards, interceptors, and the endpoint, and then does its teardown with the finished `Response` available. Use it when something has to span the whole request, such as a `Zone` value, a database transaction, or a `try`/`finally` cleanup.

For the common case of one instance per request, [request-scoped dependencies][request-scoped] already give every request its own DI scope. You don't need a wrapper for that.

## Example

<CodeFile name="lib/components/server_timing.dart">

```dart
import 'package:revali_router/revali_router.dart';

class ServerTiming implements LifecycleComponent {
  const ServerTiming();

  WrapperResult wrap(NextResponse next) async {
    final watch = Stopwatch()..start();

    try {
      return await next();
    } finally {
      print('request took ${watch.elapsedMilliseconds}ms');
    }
  }
}
```

</CodeFile>

Apply it with `@ServerTiming()` on the app, a controller, or an endpoint. Every request it covers is timed, including requests that a guard blocks or that throw.

## Rules

- The method must return `WrapperResult` (an alias for `Future<Response>`) **and** take a `NextResponse` parameter. Without the `NextResponse` parameter, the method is not treated as a wrapper.
- Call `next()` exactly once and return its `Response`. To short-circuit, return a `Response` without calling `next()`.
- Other parameters bind like any other component method, for example `Request`, `Data`, or `DI`.
- Several wrappers nest: the first one registered is the outermost. Its setup runs first and its teardown runs last. See [Lifecycle Order][order].
- Wrappers run after the access-control checks and before observers are notified. They don't run for OPTIONS requests, redirects, or [WebSocket][websockets] routes.

## Classic Style

As an alternative, implement `RequestWrapper`:

<CodeFile name="lib/components/server_timing_wrapper.dart">

```dart
import 'package:revali_router/revali_router.dart';

class ServerTimingWrapper implements RequestWrapper {
  const ServerTimingWrapper();

  @override
  WrapperResult wrap(Context context, NextResponse next) async {
    final watch = Stopwatch()..start();

    try {
      return await next();
    } finally {
      print('${context.request.uri} took ${watch.elapsedMilliseconds}ms');
    }
  }
}
```

</CodeFile>

Apply it with `@ServerTimingWrapper()`, or by type with `@Wrappers([ServerTimingWrapper])`.

[request-scoped]: /revali/app-configuration/configure-dependencies#request-scoped-dependencies
[order]: /constructs/revali_server/lifecycle-components#lifecycle-order
[websockets]: /constructs/revali_server/response/websockets
