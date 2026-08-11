---
title: Guards
description: Protect the execution of the endpoint
---

A `Guard` is a Lifecycle Component that is used to protect the execution of the controller and endpoint.

A guard can be used for checking if the user is authenticated, if the user has the correct permissions, or any other condition that needs to be met before the controller or endpoint is executed.

## Execution

Guards are executed after the middleware, before the interceptors.

## Create a Guard

To create a `Guard`, you need to implement the `Guard` class and implement the `protect` method.

<CodeFile name="lib/components/guards/my_guard.dart">

```dart
import 'package:revali_router/revali_router.dart';

class MyGuard implements Guard {
    const MyGuard();

    @override
    Future<GuardResult> protect(Context context) async {
        return const GuardResult.pass();
    }
}
```

</CodeFile>

<Callout type="note">

There's no limit to the number of guards that can be applied to a controller or endpoint. Guards are executed in the order they are registered.

</Callout>

### Possible Results

The `GuardResult` has two possible results: `pass` and `block`. The `pass` result allows the request to continue to the controller or endpoint. The `block` result stops the request from continuing any further in the request flow.

```dart
const GuardResult.pass();
```

```dart
const GuardResult.block(
    statusCode: 403,
    headers: {},
    body: 'User does not have the correct role to access this resource.',
);
```

An alternative to using the `GuardResult.block` method is to throw an exception. Create an [exception catcher][exception-catchers] to catch the exception and handle the error response.

<Callout type="tip">

Learn about [returning error responses][error-responses].

<Callout type="important">

If the `statusCode` is not set, the default status code will be 403.

</Callout>

</Callout>

## Register the Guard

To register the `Guard`, annotate your `Guard` class on the app, controller, or endpoint level.

<CodeFile name="routes/controllers/my_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyGuard()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

</CodeFile>

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `Guard` as a type reference using the `@Guards()` annotation.

<CodeFile name="routes/controllers/my_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Guards([MyGuard])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

</CodeFile>

<Callout type="tip">

Learn more about [type referencing][type-referencing].

</Callout>

## Example

In this example, we have a `RoleGuard` that checks if the user has the correct role to access a resource.

<CodeFile name="lib/components/guards/role_guard.dart">

```dart
import 'package:revali_router/revali_router.dart';

class RoleGuard implements Guard {
  const RoleGuard(this.role);

  final String role;

  @override
  Future<GuardResult> protect(Context context) async {
    var user = context.data.get<User?>();

    if (user == null) {
      await context.request.resolvePayload();
      final id = context.request.pathParameters['id']!;

      user = await authService.getUser(id);

      if (user == null) {
        return const GuardResult.block(
          statusCode: 404,
          body: 'User not found.',
        );
      }

      context.data.add(user);
    }

    if (user.role != role) {
      return const GuardResult.block(
        statusCode: 403,
        body: 'User does not have the correct role to access this resource.',
      );
    }

    return const GuardResult.pass();
  }
}
```

</CodeFile>

[exception-catchers]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[type-referencing]: /constructs/revali_server/tidbits#using-types-in-annotations
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
