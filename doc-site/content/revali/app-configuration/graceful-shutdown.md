---
title: Graceful Shutdown
description: Finish in-flight requests before the process exits
---

Container runtimes and process supervisors stop a process by sending
`SIGTERM`. Revali catches it, reports itself unready, stops accepting new
connections, waits for the requests already being served, and only then exits.

Without that, every deploy and every scale-down truncates whatever responses
happened to be mid-flight — the client sees a dropped connection rather than
the answer it was about to get.

You get this by default. There is nothing to enable.

## What happens on `SIGTERM`

1. Readiness starts reporting `503` immediately, while the server is **still
   accepting**. See [`drainDelay`](#draindelay) — this window exists so a load
   balancer can notice and steer away, and requests arriving during it are
   served and tracked normally rather than refused.
2. Once the window closes the listening socket does, so no new connection is
   taken.
3. Requests already in flight keep running and send their responses.
4. [`onServerStopped`](#releasing-resources) runs, so the app can release what
   it owns.
5. The process exits with status `0`.

If requests are still running when [`shutdownTimeout`](#shutdowntimeout)
elapses, the wait is abandoned and shutdown continues — a stuck handler cannot
keep the process alive forever.

`SIGINT` (Ctrl-C) follows the same path. A second signal while a shutdown is
already running is ignored rather than starting a second one.

## `shutdownTimeout`

How long to wait for in-flight requests. Defaults to 15 seconds.

```dart
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);

  @override
  Duration get shutdownTimeout => const Duration(seconds: 25);
}
```

<Callout type="important">

Keep this **below** the grace period of whatever supervises the process.
Kubernetes sends `SIGKILL` 30 seconds after `SIGTERM` by default, and being
killed part-way through the drain defeats the point of draining at all.

</Callout>

## Releasing resources

Override `onServerStopped` to close what the app owns — database pools,
message consumers, file handles. It runs *after* in-flight requests have
finished, so nothing still serving a request has its connection pulled out
from under it.

```dart
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> onServerStopped() async {
    await database.close();
  }
}
```

Throwing from `onServerStopped` is logged and does not stop the shutdown.

## Owning signal handling yourself

Set `handleShutdownSignals` to false if something else in your process
already installs handlers, or you want to sequence shutdown differently:

```dart
@override
bool get handleShutdownSignals => false;
```

Nothing else changes — the server simply stops listening for signals, and
exiting becomes your responsibility.

<Callout type="note">

Signal handlers are only installed for a server Revali created and owns. They
are never installed when you pass your own `HttpServer` to `createServer`
(which is what [`TestServer`](/revali/testing) does), nor in worker isolates,
which share the parent process's signals.

</Callout>

## What's next?

- [Create an App](/revali/app-configuration/create-an-app) — the rest of `AppConfig`
- [`revali build`](/revali/cli/build) — produce the executable that receives these signals
