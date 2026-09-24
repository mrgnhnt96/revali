---
title: Create an App
description: Define the @App that sets host, port and prefix, and use flavors to switch between apps
---

An app file sets where your server listens. Create one when the defaults (`localhost:8080`, prefix `api`) aren't what you want, or when you need to register dependencies.

```bash
dart run revali create app            # scaffolds an app file in routes/apps/
```

See [`revali create`](/revali/cli/create) for more.

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp()
      : super(
          host: 'localhost',
          port: 8080,
          prefix: 'api', // routes are served under /api
        );
}
```

</CodeFile>

Revali finds the app from these rules:

- The file must be under `routes/`. The convention is `routes/apps/`.
- The file must be named `app.dart`, `*_app.dart` or `*.app.dart`.
- The class must be annotated with `@App()` and extend `AppConfig`, imported from `package:revali_router/revali_router.dart`.
- The constructor may take an [`Args`](/revali/cli/dev#server-arguments) parameter. Nothing else is injected into it: the app is created before dependency injection is set up.

## Host, Port and Prefix

| Parameter | Default | Notes |
| --- | --- | --- |
| `host` | required | Use `localhost` for local development and `0.0.0.0` in a container. |
| `port` | required | `0` picks a free port, which is useful in tests. |
| `prefix` | `'api'` | Written without slashes: `'api'` or `'api/v1'`, never `'/api'`. A leading or trailing `/` throws when the server starts. Use `null` or `''` for no prefix. |
| `workers` | `1` | See [Worker Isolates](/revali/app-configuration/workers). |
| `backlog` | `0` | The listen backlog. `0` uses the OS default. |

The prefix applies to every route except the [health probes](/revali/app-configuration/health-probes). A controller at `@Controller('users')` is served at `/api/users`.

### Reading Host and Port from the Environment

In a deployment, the platform usually decides the port. `AppConfig.fromEnv` reads `HOST` (default `0.0.0.0`) and `PORT` (default `8080`):

<CodeFile name="routes/apps/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv(); // not const: it reads the environment at runtime
}
```

</CodeFile>

`revali up` and `revali compose` pass each service its port through `PORT`. See [Environment Variables](/revali/app-configuration/env-vars#appconfigfromenv).

### Trusted Proxy

Behind a reverse proxy or load balancer, override `trustedProxy`. Then `request.ip` and `@Ip()` report the client's address from the proxy headers instead of the proxy's own address:

<CodeFile name="routes/apps/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: '0.0.0.0', port: 8080);

  @override
  TrustedProxy get trustedProxy => const TrustedProxy(
        headers: ['X-Forwarded-For'],
      );
}
```

</CodeFile>

Keep the default (`const TrustedProxy()`) when clients connect to the server directly, so they can't spoof their IP through these headers. See [Client IP](/constructs/revali_server/request/client-ip).

## Flavors

A project can define several apps, one per environment. Give each app a `flavor` and pick one at run time with `--flavor`:

<CodeFile name="routes/apps/dev_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
final class DevApp extends AppConfig {
  const DevApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton<EmailService>(FakeEmailService.new);
  }
}
```

</CodeFile>

<CodeFile name="routes/apps/prod_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App(flavor: 'prod')
final class ProdApp extends AppConfig {
  ProdApp() : super.fromEnv();

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton<EmailService>(SmtpEmailService.new);
  }
}
```

</CodeFile>

```bash
dart run revali dev --flavor dev
dart run revali build --flavor prod
```

Revali picks the app as follows:

- **Only one server runs.** The CLI selects a single app. Two apps can't serve different ports from one package.
- **Flavor names are case-sensitive.** `dev` and `Dev` are different flavors.
- **Without `--flavor`:** if only one app exists, it runs. If there are several, the first app without a flavor runs. If every app has a flavor, generation fails with `No app found, did you forget pass the --flavor arg?` and a list of the configured flavors.
- **With `--flavor` but no matching app:** generation fails with `No app found for flavor "<name>"`.

Put values that change between deployments of the same build, such as secrets and URLs, in [environment variables](/revali/app-configuration/env-vars) rather than in flavors.
