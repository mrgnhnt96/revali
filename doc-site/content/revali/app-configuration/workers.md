---
title: Worker Isolates
description: Run the server in several isolates on one port, and know what they don't share
---

One isolate uses one CPU core. That's plenty when handlers mostly wait on a database or another service. When handlers do heavy CPU work, set `workers` to run several isolates on the same port. The OS spreads incoming connections across them.

<CodeFile name="routes/apps/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  MainApp()
      : super.fromEnv(
          workers: Env.current.integer('WORKERS', orElse: 1),
        );
}
```

</CodeFile>

`workers` defaults to `1`. Read it from the environment, because production containers rarely have as many cores as your laptop. `backlog` (default `0`, the OS default) is worth raising only when many connections arrive in bursts.

## What Isolates Don't Share

Every isolate creates its own `AppConfig`, runs its own `configureDependencies`, and opens its own connections. **Dart isolates share no memory.**

| | `workers: 1` | `workers: 4` |
| --- | --- | --- |
| An in-memory cache | 1 cache | 4 separate caches |
| A rate-limit counter in a `Map` | counts every request | each isolate counts about a quarter of the requests |
| A database pool of 10 | 10 connections | 40 connections |
| A `static` field | 1 value | 4 values |

Anything that must be shared across isolates belongs in Redis or your database, not in a field.

## `IsolateIdentity`

```dart
final me = IsolateIdentity.current;

me.index;        // 0 for the parent, 1..workerCount - 1 for workers
me.workerCount;  // the value of `workers`
me.isWorker;     // index > 0
```

Use it for work that must run once per process rather than once per isolate:

```dart
@override
Future<void> configureDependencies(DI di) async {
  if (!IsolateIdentity.current.isWorker) {
    di.registerSingleton<NightlyReport>(NightlyReport()..start());
  }
}
```

In tests, or in an app with a single isolate, `current` has index `0`, is not a worker, and reports a `workerCount` of `1`. Don't call `IsolateIdentity.setCurrentForGeneratedCode`: the generated server calls it for you.

## Handled for You

- **Message consumers** register in every isolate. `RedisBroker` adds the isolate index to worker consumer names (`<name>-1`, `<name>-2`, …). See [Messaging](/revali/messaging#name-your-replicas).
- **Shutdown**: on `SIGTERM` the parent tells every worker to drain, so readiness reports `503` from every isolate at the same time. See [Graceful Shutdown](/revali/app-configuration/graceful-shutdown).
- **`revali dev`**: on each reload, the previous workers are stopped before new ones start.
