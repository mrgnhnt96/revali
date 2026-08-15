---
title: Health Probes
description: Liveness and readiness endpoints that tell an orchestrator when to restart and when to route elsewhere
---

Every Revali server answers two probe endpoints out of the box:

| Path | Question | A failure means |
| --- | --- | --- |
| `GET /healthz` | Is this process wedged? | **Restart me** |
| `GET /readyz` | Should traffic come here? | **Route elsewhere**, leave the process alone |

You get both by default. There is nothing to enable.

## Why readiness is separate from liveness

Conflating the two is the usual way a deploy goes wrong, and it goes wrong in
both directions.

Point a liveness probe at your database and one database blip restarts every
pod at once — a restart storm, caused by a dependency the process could have
waited out. That is why `/healthz` runs no checks at all. It reports that the
isolate is alive and its event loop is turning, and nothing else.

Fail readiness instead and nothing is killed: the load balancer stops sending
new requests to that instance, the process keeps serving what it already has,
and traffic comes back the moment the probe recovers.

The difference matters most during a shutdown. Readiness flips to 503 the
instant a drain begins, while liveness keeps returning 200 for the whole
drain. If liveness failed mid-drain, the orchestrator would kill the process
and truncate exactly the in-flight requests the drain exists to protect.

## Where the probes are served

Probes are registered **outside** your app's `prefix`. With the default prefix
of `api`, your routes live under `/api` but the probes answer on bare
`/healthz` and `/readyz`.

That is deliberate. Orchestrators are configured with literal paths in a
manifest, and a probe should not have to track an application routing concern.
Moving your prefix never breaks your Kubernetes config.

## What the probes return

Liveness is always the same:

```json
{ "status": "ok" }
```

Readiness with no checks registered is a plain `200`:

```json
{ "status": "ok" }
```

With checks registered, each one is named in the body — so a `503` tells you
*which* dependency is down rather than just that something is:

```json
{
  "status": "unhealthy",
  "checks": {
    "database": { "status": "ok" },
    "queue": { "status": "unhealthy", "detail": "broker down" }
  }
}
```

And once a shutdown has begun, readiness short-circuits — it does not even run
the checks:

```json
{ "status": "draining" }
```

## Registering readiness checks

A `HealthCheck` is one dependency the readiness probe consults. Implement
`name` and `check()`:

<CodeFile name="lib/health/database_is_reachable.dart">

```dart
import 'package:revali_router/revali_router.dart';

class DatabaseIsReachable implements HealthCheck {
  const DatabaseIsReachable(this.db);

  final Database db;

  @override
  String get name => 'database';

  @override
  Future<HealthCheckResult> check() async {
    try {
      await db.ping();
      return const HealthCheckResult.healthy();
    } catch (e) {
      return HealthCheckResult.unhealthy('$e');
    }
  }
}
```

</CodeFile>

Register them by overriding `health` on your `AppConfig`:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  MainApp(this.db) : super(host: 'localhost', port: 8080);

  final Database db;

  @override
  HealthSettings get health => HealthSettings(
        checks: [DatabaseIsReachable(db)],
      );
}
```

</CodeFile>

Some rules worth knowing before you write one:

- **All checks run concurrently.** The probe costs the slowest check, not the
  sum of them.
- **Any failure fails the whole probe.** One unhealthy check makes the
  response `503`, and the body still lists the healthy ones.
- **A check that throws is unhealthy, not a 500.** A probe that 500s tells the
  orchestrator strictly less than one that names the broken dependency, so
  exceptions are caught and reported as `unhealthy` with the error as the
  `detail`.
- **`detail` is human-facing context, not a debug dump.** A readiness endpoint
  is typically reachable by anything that can reach the pod, so a connection
  string or a credential does not belong in it.
- **`name` is a label.** Keep it stable — it is the key in the response body
  that alerting will match on.

### Choose checks that should actually pull you out of rotation

Add a check only when the service cannot usefully serve traffic without that
dependency: a primary database, a required upstream.

A cache your service degrades gracefully without should **not** be a readiness
check. Make it one and a single slow cache node takes the whole service out of
rotation, converting a minor latency problem into an outage.

### `checkTimeout`

How long a single check may take before it counts as unhealthy. Defaults to 5
seconds.

```dart
@override
HealthSettings get health => HealthSettings(
      checks: [DatabaseIsReachable(db)],
      checkTimeout: const Duration(seconds: 2),
    );
```

A timed-out check reports `unhealthy` with a `timed out after 2000ms` detail,
so a hanging dependency is named rather than silently stalling the response.

<Callout type="important">

Keep `checkTimeout` **below** your orchestrator's own probe timeout. If the
orchestrator gives up first, the connection is cut before Revali can report
which dependency was slow, and you lose the one piece of information the probe
existed to give you.

</Callout>

Setting `checkTimeout` to `Duration.zero` disables the timeout entirely, and a
hanging check will then hang the probe. Prefer a short timeout.

## Readiness during shutdown

When a shutdown begins, the drain is flagged *before* the listening socket
closes, and `/readyz` reads that flag on every request. From that moment on it
returns `503 {"status":"draining"}` — checks are not run, because the answer is
already "do not send me traffic" regardless of what the database says.

See [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) for the
rest of the sequence.

### `drainDelay`

Here is the problem `drainDelay` solves: **closing a listening socket is
invisible to a load balancer.** The balancer keeps routing to the instance
until its *own* readiness probe fails, and every request it sends in the
meantime hits a closed socket — a connection error the client sees, during a
shutdown that was supposed to be graceful.

`drainDelay` is a window in which readiness already reports `503` while the
server is **still accepting and serving**. It gives the balancer time to notice
and steer away before the door shuts, instead of after.

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Duration get drainDelay => const Duration(seconds: 30);

  @override
  Duration get shutdownTimeout => const Duration(seconds: 15);
}
```

Requests that arrive during the delay are served and tracked normally — the
accept loop does not refuse while draining, so nothing that arrives in the
window is dropped. They are drained along with everything else.

The default is `Duration.zero`: the socket closes immediately. That is the
right default for a process nothing is load balancing in front of, and the
wrong one behind a balancer.

Sizing it, per the framework's own guidance:

- Set it **longer than your probe's period times its failure threshold**.
  Kubernetes defaults to 10s × 3, so 30s or more is not unusual — the balancer
  needs enough consecutive failures to actually mark the instance down.
- Keep **`drainDelay + shutdownTimeout` under the platform's kill grace
  period**, which Kubernetes defaults to 30 seconds. Being killed by `SIGKILL`
  part-way through defeats the point of draining at all.

<Callout type="note">

`drainDelay` is applied on `SIGTERM` only. `SIGINT` is a human at a terminal
who wants the process gone now, and making Ctrl-C sit through a 30-second
delay would be a poor trade.

</Callout>

## Every worker isolate reports 503, not just one

This is the part that is easy to get wrong, and Revali handles it for you.

With `workers` greater than 1, every isolate binds the same port with
`shared: true` and the OS distributes connections across them. Each isolate
keeps its **own** in-flight request set, and only the parent watches for
signals.

Left alone, that splits readiness: `SIGTERM` reaches the parent, the parent
flags *its* drain — and a probe the OS happens to balance onto a worker isolate
answers `200 ok`, cheerfully telling the load balancer to keep sending traffic
to a process that is on its way out. The same split would strand requests: the
parent's `exit(0)` takes every other isolate's in-flight requests down with it.

So the parent does not drain alone. On `SIGTERM` it tells every registered
worker to drain and drains itself **concurrently**, so each isolate flags its
own readiness at the same moment and probes report `503` across the whole fleet
rather than only whichever isolate caught the signal. The process exits once
every worker has reported back.

That fleet-wide wait is bounded by `drainDelay + shutdownTimeout`. A worker
that died, never registered, or hangs costs you the timeout — it cannot keep
the process alive forever.

Worker isolates never install signal handlers of their own, for the same
reason: an `exit()` from a worker would take the whole process down with
requests still running elsewhere.

## Changing the paths

Both paths are configurable, and either probe can be turned off on its own by
setting its path to `null`:

```dart
@override
HealthSettings get health => const HealthSettings(
      livenessPath: '/alive',
      readinessPath: '/ready',
    );
```

```dart
// Liveness off, readiness still served on /readyz.
@override
HealthSettings get health => const HealthSettings(livenessPath: null);
```

To serve no probes at all:

```dart
@override
HealthSettings get health => const HealthSettings.disabled();
```

A path that is disabled — or any path other than the configured ones — is
simply not a route, and answers `404`.

## Wiring it up in Kubernetes

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
readinessProbe:
  httpGet:
    path: /readyz
    port: 8080
    # Keep this above HealthSettings.checkTimeout so a slow check gets to
    # report which dependency was slow.
    timeoutSeconds: 10
```

Note the absence of a prefix on either path — probes are served outside it.

## What's next?

- [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) — the full
  `SIGTERM` sequence, `shutdownTimeout`, and `onServerStopped`
- [Worker Isolates](/revali/app-configuration/workers) — what `workers` changes,
  and what each isolate does and does not share
- [Create an App](/revali/app-configuration/create-an-app) — the rest of
  `AppConfig`

<!-- The default probe paths, which are conventions rather than English words. -->

