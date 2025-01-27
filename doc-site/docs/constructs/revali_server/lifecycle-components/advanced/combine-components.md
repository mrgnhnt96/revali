---
description: Combine multiple Lifecycle Components into a single group
sidebar_position: 5
---

# Combine Components

There are types when you have multiple Lifecycle Components that should be grouped together. For example, you may want to group all the Auth components (`AuthMiddleware`, `AuthExceptionCatcher`, `AuthGuard`, `AuthInterceptor`, etc) together. You could annotate each one individually, or you can use a `CombineComponents` class to group them together.

## Execution

Combine components themselves are not executed, but the components they contain are. The components are executed with their respective types.

## Create a Combine Component

To create a `CombineComponent`, create a class that extends `CombineComponents`.

```dart title="lib/components/auth_components.dart"
import 'package:revali_router/revali_router.dart';

class AuthComponents implements CombineComponents {
    const AuthComponents();

    @override
    List<ExceptionCatcher<Exception>> get catchers => [AuthExceptionCatcher()];

    @override
    List<Guard> get guards => [AuthGuard()];

    @override
    List<Interceptor> get interceptors => [AuthInterceptor()];

    @override
    List<Middleware> get middlewares => [AuthMiddleware()];
}
```

::::important
In order to use `AuthComponents` as an annotation, the constructor must be a constant constructor.
::::

## Register the Combine Components

To register the `CombineComponents`, annotate your `CombineComponents` class on the app, controller, or endpoint level.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@AuthComponents()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

### As Type Reference

If any of your components require parameters that cannot be provided at compile time, resulting in the constructor not being a constant constructor. In this case, you can register the `AuthComponents` as a type reference using the `@Combines` annotation.

```dart title="lib/components/auth_components.dart"
import 'package:revali_router/revali_router.dart';

class AuthComponents implements CombineComponents {
    const AuthComponents({
        required this.service,
    });

    final AuthService service;

    ...
}
```

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Combines(AuthComponents)
@Get('')
Future<void> myEndpoint() {
    ...
}
```

:::tip
Learn more about [type referencing][type-referencing].
:::

[type-referencing]: ../../tidbits.md#using-types-in-annotations
