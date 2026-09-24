---
title: Data Sharing
description: Pass values between lifecycle components and endpoints within one request, keyed by type.
---

`Data` is a per-request store that lifecycle components and endpoints use to hand values to each other, such as a middleware that loads the current user for a guard and the endpoint to use. Values are keyed by their **type**, and each request starts with an empty store.

## Example

A middleware stores the user, a guard checks it, and the endpoint receives it with `@Data()`:

<CodeFile name="lib/components/auth.dart">

```dart
import 'package:revali_router/revali_router.dart';

class Auth implements LifecycleComponent {
  const Auth(this.users); // from DI

  final UserService users;

  Future<MiddlewareResult> load(@Header('Authorization') String? token, Data data) async {
    if (token != null) {
      if (await users.fromToken(token) case final user?) {
        data.add<User>(user);
      }
    }

    return const MiddlewareResult.next();
  }

  GuardResult require(Data data) {
    return data.has<User>()
        ? const GuardResult.pass()
        : const GuardResult.block(statusCode: 401, body: 'Sign in first');
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/me_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@LifecycleComponents([Auth])
@Controller('me')
class MeController {
  const MeController();

  @Get()
  String me(@Data() User user) => user.name;
}
```

</CodeFile>

`GET /api/me` with a valid token returns `200 {"data":"Ada"}`. Without a token, the guard returns `401 Sign in first`.

## API

| Method | Returns | Behavior |
| --- | --- | --- |
| `add<T>(T value)` | `void` | Stores `value` under type `T`, replacing any existing `T` |
| `get<T>()` | `T?` | The stored `T`, or `null` |
| `has<T>()` | `bool` | Whether a `T` is stored |
| `contains<T>(T value)` | `bool` | Whether any stored value equals `value` |
| `remove<T>()` | `bool` | Removes the stored `T`. Returns whether one was removed. |

In a component or endpoint, take `Data` as a parameter to use this API. To receive a single value in an endpoint or component, use `@Data()` on a parameter of that type:

| Parameter | When no value of that type is stored |
| --- | --- |
| `@Data() User user` | Throws `MissingArgumentException`, which Revali answers with `400 Bad Request` |
| `@Data() User? user` | Receives `null` |

## Use Your Own Types as Keys

Since the type is the key, only one `String` can be stored per request, and any component that stores a `String` overwrites it. Wrap primitive values in a small class so each one has its own key:

```dart
class TenantId {
  const TenantId(this.value);

  final String value;
}

data.add(TenantId('acme'));
final tenant = data.get<TenantId>();
```

The key is the static type `T`, which Dart infers from the argument. `data.add(user)` stores under the variable's declared type. If that is a supertype (such as `Object` or an interface) or a nullable type (`User?` is a different key from `User`), pass the type explicitly with `data.add<User>(user)`.
