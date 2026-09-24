---
title: revali dev
description: Generate and run the development server with hot reload
---

`revali dev` generates your server into `.revali/`, starts it, and regenerates and reloads it whenever a watched file changes. Use it for local development. Run it from the package root, the directory that holds `pubspec.yaml` and `routes/`.

```bash
dart run revali dev
```

The URL comes from your [app configuration](/revali/app-configuration/create-an-app). With the default app it is `http://localhost:8080/api`.

## Options

| Flag | Default | Description |
| --- | --- | --- |
| `--debug` / `--release` / `--profile` | `--debug` | Run mode. See [Run Modes](#run-modes). |
| `--flavor`, `-f <name>` | none | Selects the [`@App(flavor:)`](/revali/app-configuration/create-an-app#flavors) to run. Case-sensitive. |
| `--dart-define`, `-D <KEY=value>` | none | Compile-time constant, read with `String.fromEnvironment`. Repeatable. |
| `--dart-define-from-file <path>` | none | A file (for example `.env`) of `KEY=value` pairs, passed as constants. Repeatable. |
| `--dart-vm-service-port <port>` | `0` | Port for the Dart VM service. `0` picks a free port. |
| `--recompile` | off | Recompiles the construct kernel. Use it after changing a local construct or a `revali_*` package. |
| `--skip-if-fresh` | off | Skips kernel and construct generation when the `.revali` outputs are newer than the package sources. |
| `--inspect` | off | Records recent requests to `.revali/inspect/requests.jsonl`. |
| `--cert <path>` | none | TLS certificate chain (PEM). Serves HTTPS. Requires `--key`. See [HTTPS in Development](/revali/app-configuration/https). |
| `--key <path>` | none | TLS private key (PEM) that matches `--cert`. Requires `--cert`. |

Arguments after `--` are passed to your server. See [Server Arguments](#server-arguments).

## Run Modes

The mode is passed to the server as the `kDebugMode`, `kProfileMode` and `kReleaseMode` constants, which `revali_router` exports.

### Debug Mode (Default)

```bash
dart run revali dev
```

- Hot reload is on, and the Dart VM service is enabled so a debugger can attach.
- Asserts are enabled.
- Error responses include a `__DEBUG__` block with the exception and stack trace.

### Release Mode

```bash
dart run revali dev --release
```

- No hot reload, no VM service, and no asserts.
- Error responses don't include `__DEBUG__` details.

Use it to check how the server behaves in production without building an executable.

### Profile Mode

```bash
dart run revali dev --profile
```

This generates the server in profile mode and then exits. It doesn't start the server. To produce a profile build, use [`revali build --profile`](/revali/cli/build#build-modes).

```dart
import 'package:revali_router/revali_router.dart';

void log(String message) {
  if (kDebugMode) print('DEBUG: $message');
}
```

## Hot Reload and Hotkeys

Saving a file anywhere in the package, or in one of its path dependencies, regenerates the server and restarts it. These paths are never watched: `.revali/`, `bin/`, `test/` and `tool/`. To exclude more, see [`hot_reload.exclude`](/revali/revali-configuration#hot-reload).

While the server runs, these keys work:

| Key | Action |
| --- | --- |
| `r` | Regenerate and restart the server |
| `c` | Clear the console and reprint the status board |
| `q` | Quit (same as Ctrl+C) |

Without a TTY (CI, scripts, AI agents), write the command to `.revali_cmd` in the project root:

```bash
echo reload > .revali_cmd
echo clear > .revali_cmd
echo quit > .revali_cmd
```

After each start or reload, the console prints a status board:

```text
12:34:56 PM [READY]
Serving at http://localhost:8080/api
Press: r reload, c clear, q quit

/users
GET -> /users/
```

## Generate Without Running

```bash
dart run revali dev --generate-only
```

This writes `.revali/server/server.dart` and `routes.json` and then exits. The exit code is non-zero when your routes fail analysis. Tests and [`revali routes`](/revali/cli/routes) need this output to exist. Add `--recompile` if you changed a construct or a `revali_*` package.

## Server Arguments

Everything after `--` is passed to your server process. Your app receives it as `Args` when its constructor declares an `Args` parameter:

```bash
dart run revali dev -- --port 8081 --verbose
```

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  MainApp(this.args)
      : super(
          host: 'localhost',
          port: int.parse(args['port'] as String? ?? '8080'),
        );

  final Args args;

  @override
  Future<void> configureDependencies(DI di) async {
    final verbose = args.flags['verbose'] ?? false;
    // ...
  }
}
```

</CodeFile>

`Args` follows these parsing rules:

- `--key value` and `--key=value` give a `String`.
- `--flag` gives `true`, and `--no-flag` gives `false`.
- A repeated key gives a list.
- Values that don't start with `--` go into `args.rest`.

The members are `args['key']`, `args.get<T>('key')`, `args.wasParsed('key')`, `args.flags` (booleans only) and `args.values`.

## Debugging

In debug mode the status board prints the VM service URL. Attach to it from your IDE:

- VS Code: **Dart: Attach to Dart Process**, then paste the URL.
- IntelliJ / Android Studio: **Run → Attach to Process** (Dart remote debug).

Set `--dart-vm-service-port` to keep the port the same between runs.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Port already in use | Stop the other process (`lsof -i :8080`) or change `port` in your app. |
| A controller doesn't reload | The file must be under `routes/` and end with `_controller.dart` or `.controller.dart`. Press `r` to force a regenerate. |
| A change to a construct has no effect | Run again with `--recompile`. |
| `No app found for flavor` | The `--flavor` value must match an `@App(flavor:)` exactly. |
