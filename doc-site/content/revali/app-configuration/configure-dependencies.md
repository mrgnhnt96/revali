---
title: Configure Dependencies
description: Register services in the DI container and inject them into controllers, components and handlers
---

Register services once in your app's `configureDependencies`. Revali then passes them to controller constructors, handler parameters and lifecycle components, so you never construct them by hand.

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:my_app/repos/user_repository.dart';
import 'package:my_app/services/user_service.dart';
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..registerLazySingleton<UserRepository>(UserRepository.new)
      ..registerLazySingleton<UserService>(
        () => UserService(di.get<UserRepository>()),
      );
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/user_controller.dart">

```dart
import 'package:my_app/services/user_service.dart';
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UserController {
  const UserController(this._users); // resolved from DI

  final UserService _users;

  @Get()
  Future<List<User>> list() => _users.all();

  @Get(':id')
  Future<User> get(@Param() String id, @Dep() AuditLog audit) async {
    audit.read(id); // handler parameters use @Dep()
    return _users.find(id);
  }
}
```

</CodeFile>

Import your own code with `package:` imports, not relative paths such as `../lib/...`. The container looks services up by type, and a file imported both ways defines two different types.

## Registration Methods

| Method | Lifetime | Use for |
| --- | --- | --- |
| `registerSingleton<T>(instance)` | The whole process. You create the instance up front. | Config objects, instances that are already open |
| `registerLazySingleton<T>(factory)` | The whole process. Created on first use. | Connection pools, clients, stateless services |
| `registerRequestScoped<T>(factory)` | One request | Transactions, units of work, the current user. See [below](#request-scoped-dependencies). |
| `registerFactory<T>(factory)` | A new instance on every resolution | Cheap, stateful helpers |
| `get<T>()` | | Resolves `T`. Use it inside factories to wire up dependencies. |

- **Register against an interface** (`registerLazySingleton<UserRepository>(PostgresUserRepository.new)`) so a test app can register a fake instead.
- **Tear-offs only work for constructors with no arguments.** For a constructor that takes a dependency, use a closure that calls `di.get<T>()`.
- **Each worker isolate has its own container.** With [`workers`](/revali/app-configuration/workers) greater than 1, `configureDependencies` runs once in every isolate.

## Where Dependencies Are Injected

| Where | How |
| --- | --- |
| Controller constructor | Automatically. `@Dep()` is optional. |
| Handler parameter | `@Dep() MyService service` |
| Lifecycle component method parameter | `@Dep() MyService service` |
| Custom annotation argument | An [`Inject`](#the-inject-marker-class) marker |

## Request-Scoped Dependencies

`registerRequestScoped` creates an instance **once per request** and shares it with everything that runs for that request. Nothing is shared between requests.

```dart
@override
Future<void> configureDependencies(DI di) async {
  di
    ..registerSingleton<Database>(Database(pool))
    ..registerRequestScoped<UnitOfWork>(() => UnitOfWork(di.get<Database>()));
}
```

```dart
@Post()
Future<Order> create(@Body() OrderBody body, @Dep() UnitOfWork work) =>
    work.orders.insert(body);
```

- Middleware, guards, interceptors, the handler and exception catchers all receive **the same instance** for one request.
- The instance is created the first time something asks for it. A request that never asks doesn't create one.
- If the class implements `Disposable`, `dispose()` runs when the request ends, including when the request throws. It runs after the response is fully written, which matters for streaming and SSE handlers. Instances are disposed in reverse creation order. An error thrown from `dispose` is logged, and the remaining instances are still disposed.
- Each [message consumer](/revali/messaging) call gets its own scope, just like a request.
- Resolving the dependency outside a request (at startup, or in a timer) throws `Bad state: … is registered as request scoped and cannot be resolved outside a request.` Register it as a singleton or a factory if you need it there.

```dart
class UnitOfWork implements Disposable {
  UnitOfWork(Database db) : _transaction = db.begin();

  final Transaction _transaction;

  @override
  Future<void> dispose() => _transaction.commit();
}
```

## The `Inject` Marker Class

Annotation arguments must be compile-time constants, so a service can't be passed to an annotation directly. [`Inject`][inject] fixes this. Write a `const` marker class that extends `Inject` and implements the service's type. Revali replaces the marker with the registered instance at run time.

<CodeFile name="lib/di/inject_service.dart">

```dart
import 'package:revali_router/revali_router.dart';

final class InjectService extends Inject implements Service {
  const InjectService();
}
```

</CodeFile>

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent(this.statusCode, this.service);

  final int statusCode;
  final Service service;
}

@MyComponent(200, InjectService())   // not MyComponent(200, Service()): that isn't const
@Get()
User getUser() => ...;
```

`Service` must be registered in `configureDependencies` like any other dependency. Use `Inject` only inside annotation arguments. Everywhere else, use `@Dep()` or constructor injection.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| A dependency isn't found | It isn't registered, it was registered under a different type (the implementation instead of the interface), or it was imported both relatively and through `package:`. |
| State leaks between requests | A stateful object was registered as a singleton. Use `registerRequestScoped` or `registerFactory` instead. |

[inject]: https://pub.dev/documentation/revali_annotations/latest/revali_annotations/Inject-class.html
