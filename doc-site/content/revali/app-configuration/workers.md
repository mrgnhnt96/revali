---
title: Worker Isolates
description: Run the server in several isolates, and tell them apart
---

A Dart isolate runs on one thread. A handler that spends its time waiting — on a database, on another service — leaves that thread free and one isolate is plenty. A handler that spends its time *computing* does not, and every other request waits behind it however many cores the machine has.

`workers` is the answer to the second case:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp()
      : super(
          host: '0.0.0.0',
          port: 8080,
          workers: 4,
        );
}
```

</CodeFile>

Four isolates, all bound to port `8080` with `shared: true`, and the OS distributes incoming connections across them. Defaults to `1`.

<Callout type="tip">

Match `workers` to the cores you actually have. The container in production rarely has the core count your laptop does, so it is usually worth reading rather than baking in — which means giving up `const`:

```dart
MainApp()
    : super.fromEnv(
        workers: Env.current.integer('WORKERS', orElse: 1),
      );
```

See [Environment Variables](/revali/app-configuration/env-vars).

</Callout>

## What Each Isolate Gets

Every isolate runs the whole boot: it builds its own `AppConfig`, runs its own `configureDependencies`, and opens its own connections. Nothing is shared between them, because **Dart isolates share no memory at all**.

That is the part worth internalizing before turning `workers` up, because it changes what some perfectly ordinary code means:

| | With `workers: 1` | With `workers: 4` |
|---|---|---|
| An in-memory cache | One cache | Four caches, each with a quarter of the traffic and none of the others' entries |
| A rate-limit counter in a `Map` | Counts every request | Counts a quarter of them, four times over |
| A database pool of 10 | 10 connections | 40 connections |
| A `static` field | One value | Four independent values |

Anything that has to be counted, shared, or agreed on across the fleet belongs somewhere the isolates can all see — Redis, the database — not in a field. The rest is a straight win.

<Callout type="note">

`backlog` sets the listen backlog passed to `HttpServer.bind`. `0` means use the OS default. It is worth raising under connection bursts with several workers, and worth leaving alone otherwise.

</Callout>

## Which Isolate Am I?

Isolates being identical is the point, and also the problem: some things a server talks to identify their clients **by name**, and four isolates announcing the same name is four clients an external system believes are one.

`IsolateIdentity.current` tells them apart:

```dart
final me = IsolateIdentity.current;

me.index;        // 0 for the parent, 1..workerCount - 1 for a worker
me.workerCount;  // what `workers` was set to
me.isWorker;     // index > 0
```

Read it from anywhere, including code that has no way to be handed configuration — an `AppConfig.createBroker` override takes no arguments, and neither does `configureDependencies` know which isolate it is being run in.

The common use is work that must happen **once for the process**, not once per isolate:

<CodeFile name="routes/main_app.dart">

```dart
@override
Future<void> configureDependencies(DI di) async {
  di.registerLazySingleton<OrderRepository>(OrderRepository.new);

  // Four isolates would otherwise run this on four schedules.
  if (!IsolateIdentity.current.isWorker) {
    di.registerSingleton<NightlyReport>(NightlyReport()..start());
  }
}
```

</CodeFile>

Statics in Dart are per-isolate, which is not a caveat here but the whole mechanism: a static *can* describe "which isolate am I" precisely because every isolate has its own copy, and there is no race to guard against.

Unset, it describes the parent of a single-isolate app — index `0`, not a worker, one isolate in total. So a unit test, a `dart test` run, or an app that never spawns workers reads something true without configuring anything, and there is no null to handle.

<Callout type="important">

`IsolateIdentity.setCurrentForGeneratedCode` is framework plumbing. The generated server file calls it once per isolate, before any application code runs. Calling it yourself means lying about which isolate you are in, and whatever reads `current` to name itself will believe you.

</Callout>

## What Is Already Handled

Two things that would otherwise break under `workers` greater than 1 are handled for you, and both are worth knowing about because both are silent when they go wrong elsewhere.

### Consumers register in every isolate

Redis tracks unacknowledged entries **per consumer name**. Four isolates sharing one name means each isolate's pending messages are invisible to the others.

`RedisBroker` appends the isolate index for you: the parent keeps the name you configured, and the workers become `<name>-1`, `<name>-2`, and so on. See [Messaging](/revali/messaging).

### Every isolate reports `503` while draining

`SIGTERM` reaches the parent only, and each isolate keeps its own in-flight request set. Left alone, a readiness probe balanced onto a worker would answer `200` for a process on its way out.

So the parent does not drain alone: it tells every worker to drain and drains itself concurrently, so probes report `503` across the whole fleet at once. See [Health Probes](/revali/app-configuration/health-probes).

## During Development

`revali dev` binds with `shared: true` regardless, so hot reload keeps working. On reload the parent kills the previous generation of worker isolates before spawning the new one — otherwise every restart would leave another four behind, still holding the port.

## What's next?

- [Health Probes](/revali/app-configuration/health-probes) — how readiness behaves across the fleet
- [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) — the drain every isolate takes part in
- [Messaging](/revali/messaging) — consumers, and the names they register under
