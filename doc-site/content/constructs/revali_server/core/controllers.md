---
title: Controllers
description: Group related endpoints under one URL path with a @Controller class
---

A controller is a class annotated with `@Controller(path)` whose annotated methods become HTTP endpoints. Use one controller per resource (users, orders, ...); every endpoint in it is served under the controller's path.

## Minimal example

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController();

  @Get()
  List<String> list() => ['alice', 'bob'];

  @Get(':id')
  String get(@Param() String id) => 'user $id';
}
```

</CodeFile>

```bash
curl http://localhost:8080/api/users
# {"data":["alice","bob"]}

curl http://localhost:8080/api/users/42
# {"data":"user 42"}
```

To scaffold one instead, run `dart run revali create controller` (see [CLI](/revali/cli/create)).

## Rules

| Rule | Detail |
| ---- | ------ |
| Location | The file must be under `routes/`. |
| File name | Must end in `_controller.dart` or `.controller.dart`, or the file is ignored. |
| Annotation | Exactly one `@Controller` per class. |
| URL | `/<app prefix>/<controller path>/<method path>`. The app prefix defaults to `api`. |
| Method name | Not part of the URL. `@Get()` with no path binds to the controller path itself. |
| Duplicates | Two endpoints with the same HTTP method and path in one controller fail the build. |

How the pieces combine:

| Controller | Method annotation | Route |
| ---------- | ----------------- | ----- |
| `@Controller('users')` | `@Get()` | `GET /api/users` |
| `@Controller('users')` | `@Get(':id')` | `GET /api/users/:id` |
| `@Controller('users')` | `@Post()` | `POST /api/users` |
| `@Controller('shops/:shopId')` | `@Get('orders')` | `GET /api/shops/:shopId/orders` |

Path syntax (`:param`, leading slashes) is covered in [HTTP Methods](/constructs/revali_server/core/methods).

## Constructor dependencies

Constructor parameters are resolved from [dependency injection](/revali/app-configuration/configure-dependencies). `@Dep()` is optional on controller constructor parameters.

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController(this._users);

  final UserService _users;

  @Get()
  Future<List<User>> list() => _users.all();
}
```

</CodeFile>

- Revali uses the **first constructor declared** in the class. The class must have at least one public constructor; declare it first.
- A controller never receives the request directly. Read request data with [binding annotations](/constructs/revali_server/core/binding).

## Instance lifetime

| `type:` | Behavior |
| ------- | -------- |
| `InstanceType.singleton` (default) | One instance, created once and reused for every request. |
| `InstanceType.factory` | A new instance for every request. |

```dart
@Controller('users', type: InstanceType.factory)
class UsersController {
  const UsersController();
}
```

## Sharing endpoints between controllers

Annotated methods on a superclass or mixin become routes on the controller that inherits them:

```dart
abstract class CrudBase {
  const CrudBase();

  @Get('all')
  List<String> findAll() => const [];
}

mixin HealthEndpoints {
  @Get('health')
  String health() => 'ok';
}

@Controller('items')
class ItemsController extends CrudBase with HealthEndpoints {
  const ItemsController();

  @Post()
  String create() => 'created';
}
```

`ItemsController` serves `POST /api/items`, `GET /api/items/all` and `GET /api/items/health`.

- Override **with** a method annotation and yours replaces the inherited route.
- Override **without** one and the inherited route stays, dispatching to your implementation.

<Callout type="caution">

Inheriting endpoints from a **generic** base class is not supported and fails the build. The inherited signatures refer to the base's type parameters, so the generated bindings would be wrong. Declare those endpoints on the controller, or make the base non-generic.

</Callout>

Next: [HTTP Methods](/constructs/revali_server/core/methods) · [Binding](/constructs/revali_server/core/binding)
