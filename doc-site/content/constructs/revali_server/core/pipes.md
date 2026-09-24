---
title: Pipes
description: Transform or validate a bound value before it reaches the endpoint
---

A pipe is a class that receives a bound value (path parameter, query value, header, body, ...) and returns a new value for the endpoint parameter. Use one to turn an ID into a loaded object, parse a type Revali does not convert for you, or reject invalid input.

You do not need a pipe for plain JSON-to-class conversion: [binding](/constructs/revali_server/core/binding#conversion-and-missing-values) already calls your class's `fromJson`.

## Minimal example

<CodeFile name="lib/pipes/user_pipe.dart">

```dart
import 'package:revali_router/revali_router.dart';

class UserPipe implements Pipe<String, User> {
  const UserPipe(this._users);

  final UserService _users;

  @override
  Future<User> transform(String value, PipeContext context) async {
    final user = await _users.find(value);
    if (user == null) {
      throw const HttpError.notFound(
        code: 'user_not_found',
        message: 'No user with that id',
      );
    }
    return user;
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

import 'package:my_app/pipes/user_pipe.dart';

@Controller('users')
class UsersController {
  const UsersController();

  @Get(':id')
  String get(@Param.pipe(UserPipe) User user) => user.name;
}
```

</CodeFile>

```bash
curl http://localhost:8080/api/users/42
# {"data":"Ada"}

curl http://localhost:8080/api/users/999
# 404 {"error":{"code":"user_not_found","message":"No user with that id"}}
```

`HttpError` is described in [Error responses](/revali/app-configuration/default-responses#httperror). Scaffold a pipe with `dart run revali create pipe`.

## Defining a pipe

```dart
abstract interface class Pipe<T, R> {
  Future<R> transform(T value, PipeContext context);
}
```

| Part | Meaning |
| ---- | ------- |
| `T` | The type of the raw bound value the pipe accepts. Make it nullable (`String?`) to receive missing values instead of failing. |
| `R` | The type returned to the endpoint. Must match the parameter type. |
| Constructor | Parameters are resolved from [dependency injection](/revali/app-configuration/configure-dependencies). |

`PipeContext` gives access to the request [context](/constructs/revali_server/context) (`request`, `response`, `data`, `meta`, `route`, `reflect`) plus:

| Property | Value for `@Query('id', IdPipe) String id` |
| -------- | ------------------------------------------ |
| `type` | `AnnotationType.query` |
| `annotationArgument` | `'id'` |
| `nameOfParameter` | `'id'` |

## Applying a pipe

| Source | Pipe only | Name / key path and pipe |
| ------ | --------- | ------------------------ |
| Path | `@Param.pipe(P)` | `@Param('id', P)` |
| Query | `@Query.pipe(P)` | `@Query('id', P)` |
| Query, all values | `@Query.allPipe(P)` | `@Query.all('id', P)` |
| Header | `@Header.pipe(P)` | `@Header('X-Id', P)` |
| Header, all values | `@Header.allPipe(P)` | `@Header.all('X-Id', P)` |
| Cookie | `@Cookie.pipe(P)` | `@Cookie('id', P)` |
| Body | `@Body.pipe(P)` | `@Body(['user', 'id'], P)` |
| Client IP | `@Ip.pipe(P)` | |

- When the parameter is a `List`, the pipe runs once per element and receives single values.
- If the parameter has a default value, the default is used when the raw value is `null` or the pipe throws.
- A pipe whose input type is `String` (or `String?`) on a query value receives the raw string exactly as sent: `?id=42` arrives as `"42"` and `?id=1.50` as `"1.50"`. A pipe with any other input type, such as `Object`, receives the type-coerced value (`?id=42` arrives as the `int` `42`). Path, header and cookie values are always `String`.

Next: [Binding](/constructs/revali_server/core/binding) · [Request](/constructs/revali_server/request)
