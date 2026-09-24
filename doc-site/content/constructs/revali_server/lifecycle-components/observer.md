---
title: Observer
description: Watch every request and its outcome for logging and metrics, without changing either.
---

An observer is told about every request the app handles and can wait for how it turned out: the status, the duration, and the matched route. Use observers for access logs, metrics, and tracing exporters. They can't change the request or response. For that, use an [interceptor][interceptors].

Observers are registered on the **app only**.

## Example

<CodeFile name="lib/components/access_log.dart">

```dart
import 'package:revali_router/revali_router.dart';

class AccessLog implements Observer {
  const AccessLog();

  @override
  Future<void> see(ObservedRequest observed) async {
    final summary = await observed.summary;

    print(
      '${summary.method} ${summary.routePath} '
      '-> ${summary.statusCode} in ${summary.duration.inMilliseconds}ms',
    );
  }
}
```

</CodeFile>

<CodeFile name="routes/apps/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@AccessLog()
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);
}
```

</CodeFile>

`GET /api/users/42` logs `GET /api/users/:id -> 200 in 3ms`.

Scaffold one with `dart run revali create observer`. To register an observer by type, for example when its constructor needs a service from DI, use `@Observers([AccessLog])` on the app.

## `ObservedRequest`

| Field | Type | Available |
| --- | --- | --- |
| `request` | `Request` | Immediately |
| `response` | `Future<Response>` | Once the pipeline has produced the response |
| `summary` | `Future<RequestSummary>` | Once the request has finished |

`RequestSummary` has `method`, `path` (the concrete path, `/api/users/42`), `routePath` (the registered path, `/api/users/:id`, or `null` when no route matched), `statusCode`, `duration`, `startedAt`, and `error` (set when the response carried an error body).

<Callout type="tip">

Label metrics with `routePath`, not `path`. Using `path` creates one time series per id.

</Callout>

## Behavior

- `see` is called when the request enters the pipeline, and it is **not awaited**, so a slow observer never delays the response. Awaiting `observed.summary` inside `see` is safe.
- Errors thrown by an observer are caught and logged. They never affect the response or the other observers.
- Observers see requests that reach the pipeline, including requests that middleware or a guard stops, requests that throw, and requests that match no route (`404`). They are not notified for requests rejected by the [access-control checks][access-control], for OPTIONS requests, or for redirects.
- Several observers are notified in the order they are registered.

[interceptors]: /constructs/revali_server/lifecycle-components/advanced/interceptors
[access-control]: /constructs/revali_server/access-control/allow-origins
