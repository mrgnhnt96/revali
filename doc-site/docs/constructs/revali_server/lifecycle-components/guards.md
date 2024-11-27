---
description: Protect the execution of the endpoint
sidebar_position: 3
---

# Guards

A `Guard` is a Lifecycle Component that is used to protect the execution of the controller and endpoint.

A guard can be used for checking if the user is authenticated, if the user has the correct permissions, or any other condition that needs to be met before the controller or endpoint is executed.

## Execution

Guards are executed after the middleware, before the interceptors.

## Create a Guard

To create a `Guard`, you need to implement the `Guard` class and implement the `canActivate` method.

```dart title="lib/guards/my_guard.dart"
import 'package:revali_router/revali_router.dart';

class MyGuard implements Guard {
    const MyGuard();

    @override
    Future<GuardResult> canActivate(GuardContext context) async {
        return const GuardResult.yes();
    }
}
```

:::note
There's no limit to the number of guards that can be applied to a controller or endpoint. Guards are executed in the order they are registered.
:::

### Possible Results

The `GuardResult` has two possible results: `yes` and `no`. The `yes` result allows the request to continue to the controller or endpoint. The `no` result stops the request from continuing any further in the request flow.

```dart
const GuardResult.yes();
```

```dart
const GuardResult.no(
    statusCode: 403,
    headers: {},
    body: 'User does not have the correct role to access this resource.',
);
```

An alternative to using the `GuardResult.no` method is to throw an exception. Create an [exception catcher][exception-catchers] to catch the exception and handle the error response.

::::tip
Learn about [returning error responses][error-responses].

:::important
If the `statusCode` is not set, the default status code will be 403.
:::
::::

## Register the Guard

To register the `Guard`, annotate your `Guard` class on the app, controller, or endpoint level.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyGuard()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `Guard` as a type reference using the `@Guards()` annotation.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Guards([MyGuard])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

:::tip
Learn more about [type referencing][type-referencing].
:::

## Example

In this example, we have a `RoleGuard` that checks if the user has the correct role to access a resource.

```dart title="lib/guards/role_guard.dart"
import 'package:revali_router/revali_router.dart';

class RoleGuard implements Guard {
  const RoleGuard(this.role);

  final String role;

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    var user = context.data.get<User?>();

    if (user == null) {
      await context.request.resolvePayload();
      final id = context.request.pathParameters['id']!;

      user = await authService.getUser(id);

      if (user == null) {
        return const GuardResult.no(
          statusCode: 404,
          body: 'User not found.',
        );
      }

      context.data.add(user);
    }

    if (user.role != role) {
      return const GuardResult.no(
        statusCode: 403,
        body: 'User does not have the correct role to access this resource.',
      );
    }

    return const GuardResult.yes();
  }
}
```

## Guard Context

:::tip
Learn more about the Guard Context [here][guard-context].
:::

[exception-catchers]: ./exception-catchers.md
[type-referencing]: ../tidbits.md#using-types-in-annotations
[error-responses]: ../lifecycle-components/overview.md#error-responses
[guard-context]: ../context/guard.md
