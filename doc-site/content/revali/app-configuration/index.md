---
title: Overview
description: What an AppConfig is, and every setting it controls
---

An app is a class annotated with `@App()` that extends `AppConfig`. It sets where the server listens (host, port, URL prefix), registers dependencies, and controls server behavior such as compression, health probes and shutdown. You override a getter or method to change one setting and leave the rest at their defaults.

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton<UserRepository>(UserRepository.new);
  }
}
```

</CodeFile>

This server listens on `http://localhost:8080/api`. If there's no `@App` class under `routes/`, Revali uses the same defaults: `localhost`, port `8080`, prefix `api`.

## Reference

Constructor parameters. See [Create an App](/revali/app-configuration/create-an-app).

| Parameter | Default | Description |
| --- | --- | --- |
| `host` | required | The address to bind. `localhost` is bound dual-stack on `::`, so both IPv4 and IPv6 clients can connect. `0.0.0.0` binds every IPv4 interface. |
| `port` | required | The port to listen on. `0` picks a free port. |
| `prefix` | `'api'` | The path prefix for every route. Write it without slashes. `null` or `''` means no prefix. |
| `workers` | `1` | The number of isolates serving the port. See [Worker Isolates](/revali/app-configuration/workers). |
| `backlog` | `0` | The listen backlog. `0` uses the OS default. |

Constructors:

| Constructor | Use for |
| --- | --- |
| `AppConfig(...)` | Plain HTTP |
| `AppConfig.fromEnv(...)` | Host and port read from `HOST` and `PORT`. See [Environment Variables](/revali/app-configuration/env-vars#appconfigfromenv). |
| `AppConfig.secure(...)` | HTTPS with your own `SecurityContext`. See [HTTPS](/revali/app-configuration/https). |

Members you can override:

| Member | Default | Page |
| --- | --- | --- |
| `configureDependencies(DI di)` | registers nothing | [Configure Dependencies](/revali/app-configuration/configure-dependencies) |
| `defaultResponses` | plain-text 400/404/500 and CORS 403 | [Error Responses](/revali/app-configuration/default-responses) |
| `compression` | gzip on, negotiated | [Compression](/revali/app-configuration/compression) |
| `health` | `/healthz` and `/readyz` | [Health Probes](/revali/app-configuration/health-probes) |
| `shutdownTimeout`, `drainDelay`, `handleShutdownSignals`, `onServerStopped()` | 15s, 0s, `true`, no-op | [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) |
| `createBroker()` | `null` (messaging off) | [Messaging](/revali/messaging) |
| `trustedProxy` | proxy headers ignored | [Create an App](/revali/app-configuration/create-an-app#trusted-proxy) |
| `onServerStarted(HttpServer server)` | prints `Serving at …` | |
| `runStartup(start)` | calls `start()` | Wrap startup, for example in `runZoned`. |

Related pages: [Request Tracing](/revali/app-configuration/tracing) (on by default, nothing to configure) and [`revali.yaml`](/revali/revali-configuration), which configures the CLI rather than the app.
