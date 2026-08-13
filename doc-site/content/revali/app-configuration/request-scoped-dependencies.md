---
title: Request-Scoped Dependencies
description: One instance per request, disposed when the request ends
---

`registerRequestScoped` builds a dependency **once per request** and shares it
for the rest of that request. Nothing is shared between requests.

That is the missing middle between the two registrations you already have:

| Registration | Lifetime | Use for |
| --- | --- | --- |
| `registerSingleton` / `registerLazySingleton` | The whole process | Connection pools, config, clients |
| `registerRequestScoped` | One request | Transactions, units of work, the current user |
| `registerFactory` | Every resolution | Cheap, stateless helpers |

## Registering

```dart
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..registerSingleton<Database>(Database(pool))
      ..registerRequestScoped<UnitOfWork>(() => UnitOfWork(di.get<Database>()));
  }
}
```

## Resolving

Inject it the same way as anything else — in handlers, middleware, guards,
interceptors and exception catchers:

```dart
@Controller('orders')
class OrdersController {
  const OrdersController();

  @Post()
  Future<Order> create(@Body() OrderBody body, @Dep() UnitOfWork work) async {
    return work.orders.insert(body);
  }
}
```

Everything within one request gets the **same** instance, so a middleware that
records the caller and a handler that reads it are talking about the same
object — without threading it through by hand.

It is built lazily. A request that never asks for it never constructs one.

## Releasing what it holds

Implement `Disposable` and the framework releases it when the request ends:

```dart
class UnitOfWork implements Disposable {
  UnitOfWork(this._db) : _transaction = _db.begin();

  final Database _db;
  final Transaction _transaction;

  @override
  Future<void> dispose() async => _transaction.commit();
}
```

Disposal runs whether the request succeeded or threw, in **reverse creation
order** — so a dependency can rely on whatever it was built from still being
alive while it shuts down. It also runs after the response has been fully
written, which matters for streaming and SSE handlers that are still using
their resources as they send.

<Callout type="note">

Errors thrown from `dispose` are logged, not raised. The response has already
been sent by then, and one failing teardown must not skip the others.

</Callout>

## Resolving outside a request

There is no ambient request to scope to, so it throws:

```
Bad state: UnitOfWork is registered as request scoped and cannot be resolved
outside a request.
```

Building one anyway would hand back an instance nothing disposes, shared with
nobody — exactly the bug request scoping exists to prevent. If you need it
during startup, it wants to be a singleton or a factory instead.

## What's next?

- [Configure Dependencies](/revali/app-configuration/configure-dependencies) — the rest of the DI container
- [Graceful Shutdown](/revali/app-configuration/graceful-shutdown) — releasing what the *app* owns
