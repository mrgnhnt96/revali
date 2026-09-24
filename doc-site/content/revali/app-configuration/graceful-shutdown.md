---
title: Graceful Shutdown
description: Finish in-flight requests on SIGTERM, and tune drainDelay and shutdownTimeout
---

On `SIGTERM` or `SIGINT`, Revali finishes the requests it is already serving before it exits. This is on by default. Tune it when you deploy behind a load balancer or an orchestrator such as Kubernetes.

<CodeFile name="routes/apps/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv();

  @override
  Duration get drainDelay => const Duration(seconds: 10);

  @override
  Duration get shutdownTimeout => const Duration(seconds: 15);

  @override
  Future<void> onServerStopped() async {
    await database.close();
  }
}
```

</CodeFile>

| Member | Default | Description |
| --- | --- | --- |
| `drainDelay` | `Duration.zero` | How long readiness reports `503` while the server still accepts connections. Applies to `SIGTERM` only. |
| `shutdownTimeout` | 15 seconds | How long to wait for in-flight requests before giving up and exiting anyway. |
| `onServerStopped()` | no-op | Runs after requests have drained. Close database pools and file handles here. If it throws, the error is logged and shutdown continues. |
| `handleShutdownSignals` | `true` | Set to `false` to handle signals yourself. The server then stops listening for them, and exiting is up to you. |

## What Happens on `SIGTERM`

1. If the app has [message consumers](/revali/messaging#shutdown-consumers-drain-before-http), they are paused and drained first, for up to `shutdownTimeout`.
2. `/readyz` starts returning `503 {"status":"draining"}`, while the server keeps accepting and serving requests for `drainDelay`.
3. The server stops accepting new connections.
4. In-flight requests finish, for up to `shutdownTimeout`.
5. `onServerStopped()` runs, and the process exits with code `0`.

`SIGINT` (Ctrl-C) follows the same steps but skips `drainDelay`. A second signal during shutdown is ignored.

## `drainDelay`

A load balancer doesn't notice a closed socket. It keeps sending traffic until its own readiness check fails. During `drainDelay`, readiness already reports `503` but requests are still served, so the load balancer has time to stop sending traffic before the socket closes.

- Leave it at `0` when nothing load-balances in front of the server.
- Otherwise, set it longer than the probe period multiplied by the failure threshold. Kubernetes defaults to 10s × 3.
- Keep `drainDelay + shutdownTimeout` under the platform's kill grace period. Kubernetes sends `SIGKILL` after 30s by default. The consumer drain and the request drain each wait up to `shutdownTimeout`.

## Worker Isolates

With [`workers`](/revali/app-configuration/workers) greater than 1, the parent isolate tells every worker to drain at the same time as itself. Every isolate reports `503`, and the process exits once all of them have finished. That wait is bounded by `drainDelay + shutdownTimeout`. Workers never install their own signal handlers.

<Callout type="note">

Signal handlers are installed only for a server that Revali binds itself. They aren't installed when you pass your own server to `createServer`, which is what [`TestServer`](/revali/testing) does.

</Callout>
