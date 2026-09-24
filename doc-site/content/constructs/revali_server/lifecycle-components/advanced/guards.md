---
title: Guards
description: Allow or deny a request before the endpoint runs - authentication, roles, permissions.
---

A guard decides whether a request may reach the endpoint. Use one for authentication, role checks, and permissions. Guards run after all [middleware][middleware], so they can read anything middleware stored in [`Data`][data-sharing]. The example below uses the `LoadUser` middleware from [Writing a LifecycleComponent][components].

## Example

<CodeFile name="lib/components/require_role.dart">

```dart
import 'package:revali_router/revali_router.dart';

class RequireRole implements LifecycleComponent {
  const RequireRole(this.role);

  final String role;

  GuardResult check(Data data) {
    final user = data.get<User>();

    if (user == null) {
      return const GuardResult.block(statusCode: 401, body: 'Sign in first');
    }

    if (user.role != role) {
      return GuardResult.block(body: 'Requires the $role role');
    }

    return const GuardResult.pass();
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/admin_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@LifecycleComponents([LoadUser]) // middleware that stores the User in Data
@RequireRole('admin')
@Controller('admin')
class AdminController {
  const AdminController();

  @Get('stats')
  String stats() => 'ok';
}
```

</CodeFile>

| Caller | Response |
| --- | --- |
| No user loaded | `401 Sign in first` |
| A user without the `admin` role | `403 Requires the admin role` |
| An admin | `200 {"data":"ok"}` |

In debug mode, the blocked responses also have a `__DEBUG__` block appended.

## Results

| Result | Effect |
| --- | --- |
| `GuardResult.pass()` | Continue to the next guard, then to the interceptors and the endpoint. |
| `GuardResult.block({statusCode, headers, body})` | End the request. The status defaults to `403`. |

The method can be `async` and return `Future<GuardResult>`. `block` takes the same arguments as the other error results. See [Error Responses][error-responses].

You can also throw an exception from a guard and map it to a response with an [exception catcher][catchers]. That keeps the error format in one place when several guards fail the same way.

<Callout type="tip">

[`@Throttle`][throttle] is a built-in guard that answers `429` when a caller sends too many requests.

</Callout>

## Classic Style

As an alternative, implement `Guard` and its `protect` method:

<CodeFile name="lib/components/admin_guard.dart">

```dart
import 'package:revali_router/revali_router.dart';

class AdminGuard implements Guard {
  const AdminGuard();

  @override
  Future<GuardResult> protect(Context context) async {
    final user = context.data.get<User>();

    return user?.role == 'admin'
        ? const GuardResult.pass()
        : const GuardResult.block();
  }
}
```

</CodeFile>

Apply it with `@AdminGuard()`, or by type with `@Guards([AdminGuard])`.

[components]: /constructs/revali_server/lifecycle-components/components
[middleware]: /constructs/revali_server/lifecycle-components/advanced/middleware
[catchers]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[data-sharing]: /constructs/revali_server/context/data-sharing
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
[throttle]: /constructs/revali_server/lifecycle-components/kits/throttle
