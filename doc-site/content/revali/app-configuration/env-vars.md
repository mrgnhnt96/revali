---
title: Environment Variables
description: Read runtime configuration with Env and AppConfig.fromEnv, and build-time values with --dart-define
---

Revali reads configuration in two ways. Pick one by asking when the value is known:

| Kind | Set with | Read with | Changing it requires |
| --- | --- | --- | --- |
| **Runtime** (deployment) | The process environment (`export`, Docker, Kubernetes) | `Env.current` | A restart |
| **Compile time** (build) | `--dart-define`, `--dart-define-from-file` | `String.fromEnvironment` and friends | A rebuild |

Secrets and anything that differs between staging and production belong at runtime. That way one build can be promoted from one environment to the next unchanged.

## `Env`: Runtime Values

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp() : super.fromEnv();

  @override
  Future<void> configureDependencies(DI di) async {
    final env = Env.current;

    di.registerLazySingleton<Database>(
      () => Database(
        host: env.string('DB_HOST', orElse: 'localhost'),
        port: env.integer('DB_PORT', orElse: 5432),
        password: env.require('DB_PASSWORD'), // fails at startup, by name
      ),
    );
  }
}
```

</CodeFile>

```bash
DB_PASSWORD=secret dart run revali dev
```

| Method | Returns | When unset | When invalid |
| --- | --- | --- | --- |
| `env['NAME']` | `String?` | `null` | |
| `env.has('NAME')` | `bool` | `false` | |
| `env.string('NAME', orElse: …)` | `String` | `orElse` | |
| `env.require('NAME')` | `String` | **throws** | |
| `env.integer('NAME', orElse: …)` | `int` | `orElse` | **throws** |
| `env.boolean('NAME', orElse: …)` | `bool` | `orElse` | **throws** |
| `env.uri('NAME', orElse: …)` | `Uri` | `orElse`, or **throws** if there is no `orElse` | **throws** |

- **An empty or blank value counts as unset.** Orchestrators often inject `""` for variables nobody configured.
- **A malformed value throws instead of falling back.** For example, `PORT=eighty` stops the server rather than silently using `8080`.
- **`boolean` accepts** `true`/`1`/`yes`/`on` and `false`/`0`/`no`/`off`, in any case.
- **In tests, pass a map** instead of changing the real environment: `Env({'PORT': '9000'})`.

## `AppConfig.fromEnv`

`AppConfig.fromEnv` reads host and port from the environment, so the same build runs on any platform:

```dart
MainApp() : super.fromEnv();
```

| Parameter | Default |
| --- | --- |
| `hostVariable` | `'HOST'` |
| `portVariable` | `'PORT'` |
| `defaultHost` | `'0.0.0.0'` |
| `defaultPort` | `8080` |
| `prefix`, `workers`, `backlog` | same as `AppConfig` |
| `env` | `Env.current` |

- **The host defaults to `0.0.0.0`, not `localhost`.** Inside a container, a server bound to `localhost` refuses every connection from outside the container.
- **The port comes from `PORT`.** Cloud Run, Heroku, Render and Fly set `PORT`, and so do [`revali up`](/revali/cli/up) and [`revali compose`](/revali/cli/compose).
- **The constructor isn't `const`,** so your app's constructor can't be `const` either.

## Compile-Time Values

```bash
dart run revali dev --dart-define=APP_NAME=orders
dart run revali build --dart-define-from-file=.env.production
```

<CodeFile name=".env.production">

```env
APP_NAME=orders
MAX_CONNECTIONS=50
```

</CodeFile>

```dart
const appName = String.fromEnvironment('APP_NAME', defaultValue: 'app');
const maxConnections = int.fromEnvironment('MAX_CONNECTIONS', defaultValue: 100);
```

Both flags can be repeated. The values are compiled into the program, and with a [`build:` section](/revali/cli/build#compiling-a-native-executable) they are compiled into the executable. Don't use them for secrets, and keep `.env` files out of source control.
