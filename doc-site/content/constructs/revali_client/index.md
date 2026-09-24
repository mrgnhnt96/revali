---
title: Overview
description: Generate a typed Dart client package for your Revali API, then install, configure and use it
---

`revali_client` generates a standalone Dart package that calls your Revali API: one typed method per endpoint, plus a `Server` class that ties them together. Use it when a Dart or Flutter app talks to your Revali server and you want the calls type-checked against the server's code.

It is a generic construct, so it regenerates on every `revali dev` run (and on `revali build`) into `.revali/revali_client/`.

## Installation

Two packages, both in the **server** project:

| Package | Role | Section |
| --- | --- | --- |
| `revali_client_gen` | The construct (code generator) | `dev_dependencies` |
| `revali_client` | Runtime library the generated code uses; also provides `@ExcludeFromClient` | `dependencies` |

```bash
dart pub add revali_client
dart pub add --dev revali_client_gen
```

<CodeFile name="pubspec.yaml">

```yaml
dependencies:
  revali_client: ^3.0.1

dev_dependencies:
  revali: ^3.3.3
  revali_client_gen: ^2.5.0
```

</CodeFile>

No `revali.yaml` entry is required. Run the generator:

```bash
dart run revali dev
```

## Use the client in an app

The generated package lives in the server project. Add it to the consuming app as a path dependency, together with `revali_client`:

<CodeFile name="my_app/pubspec.yaml">

```yaml
dependencies:
  client: # the generated package's name: `package_name`, default `client`
    path: ../my_server/.revali/revali_client
  revali_client: ^3.0.1
```

</CodeFile>

Given a controller on the server:

<CodeFile name="my_server/routes/controllers/user_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UserController {
  const UserController();

  @Get(':id')
  Future<User> getById(@Param() String id) async => ...;
}
```

</CodeFile>

call it from the app:

<CodeFile name="my_app/lib/main.dart">

```dart
import 'package:client/client.dart';
import 'package:client/interfaces.dart';

Future<void> main() async {
  final server = Server(baseUrl: Uri.parse('https://api.example.com/api'));

  final UserDataSource users = server.user;
  final user = await users.getById(id: '123');
}
```

</CodeFile>

- `package:client/client.dart` (named after `package_name`) holds `Server` and the implementations.
- `package:client/interfaces.dart` holds the `...DataSource` interfaces and re-exports `Storage`.
- Path, query, header and body parameters become **named** arguments on the client method. `@Cookie` parameters are not arguments: the client reads them from [storage](/constructs/revali_client/storage).

Without `baseUrl`, `Server()` calls `<scheme>://<host>:<port>/<prefix>` taken from your `AppConfig` at generation time, `http://localhost:8080/api` by default. Pass `baseUrl` for anything that is not local development. See [Generated Code](/constructs/revali_client/generated-code) for everything `Server` exposes.

Any custom type in a signature must be importable by the app, so keep request and response models in a package both sides depend on. See [Sharing types](/constructs/revali_client/generated-code#sharing-types).

## Configuration

Options go under the construct's entry in the server's `revali.yaml`. All are optional.

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_client
    options:
      package_name: my_api_client
      server_name: ApiClient
      scheme: https
      integrations:
        get_it: true
```

</CodeFile>

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `package_name` | `String` | `client` | `name:` of the generated `pubspec.yaml` and of its main library, `lib/<package_name>.dart`. The output directory is always `.revali/revali_client/`. |
| `server_name` | `String` | `Server` | Name of the generated entry class. Must not contain whitespace. |
| `scheme` | `String` | `http` | Scheme of the default base URL. Has no effect when you pass `baseUrl`. |
| `integrations.get_it` | `bool` | `false` | Adds `get_it` to the generated package and a `register(GetIt)` method to `Server`. See [get_it](/constructs/revali_client/integrations/get_it). |

## Excluding endpoints

`@ExcludeFromClient()` (or the constant `@excludeFromClient`) from `package:revali_client/revali_client.dart` removes a whole controller, or a single method, from the generated client. The server still serves it.

```dart
import 'package:revali_client/revali_client.dart';
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UserController {
  const UserController();

  @Get()
  Future<List<User>> getAll() async => ...;

  @ExcludeFromClient()
  @Get('internal/stats')
  Future<UserStats> stats() async => ...;
}
```

## More

[Generated Code](/constructs/revali_client/generated-code) · [Storage & Cookies](/constructs/revali_client/storage) · [Interceptors, Timeouts & Retries](/constructs/revali_client/resilience) · [get_it](/constructs/revali_client/integrations/get_it)
