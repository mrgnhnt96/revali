---
title: get_it Integration
description: Register the generated Server and every data source with get_it in one call
---

With the `get_it` integration on, the generated `Server` class gets a `register(GetIt getIt)` method that registers the server and every data source with [get_it](https://pub.dev/packages/get_it).

## Enable it

<CodeFile name="revali.yaml">

```yaml
constructs:
  - name: revali_client
    options:
      integrations:
        get_it: true
```

</CodeFile>

The next `revali dev` adds `get_it` to the generated package's `pubspec.yaml`. If the server project already depends on `get_it`, the generated package uses the same version. Otherwise the dependency is added without a version constraint. The app that uses the client needs its own `get_it` dependency to call `GetIt`.

## Use it

```dart
import 'package:client/client.dart';
import 'package:client/interfaces.dart';
import 'package:get_it/get_it.dart';

void main() {
  Server(baseUrl: Uri.parse('https://api.example.com/api'))
      .register(GetIt.instance);

  final users = GetIt.I<UserDataSource>();
}
```

## What `register` does

```dart
void register(GetIt getIt) {
  getIt.registerSingleton(this);            // as Server
  getIt.registerLazySingleton(() => user);  // as UserDataSource
  // ...one lazy singleton per non-excluded controller
}
```

- The `Server` instance is registered as a singleton under its class name (`Server`, or your `server_name`).
- Each data source is registered as a lazy singleton under its **interface** type, so depend on `UserDataSource`, not `UserDataSourceImpl`, and swap in a fake in tests by registering your own implementation instead.
- `Storage` and `RevaliClient` are not registered. Read them from `GetIt.I<Server>().storage` and `.client`.

Calling `register` twice on the same `GetIt` throws, because get_it rejects duplicate registrations. In tests, call `GetIt.I.reset()` between runs.
