---
description: React to incoming requests by modifying the request context
sidebar_position: 2
---

# Middleware

A `Middleware` is a Lifecycle Component that is used to modify the request or response before it reaches the endpoint.

Middleware is useful for binding data to the request context, transforming the request or response, and other tasks that need to be executed before the guard or endpoint.

## Execution

Middleware is executed before the guards, in the order they are registered.

## Create a Middleware

To create a `Middleware`, you need to implement the `Middleware` class and implement the `use` method.

```dart title="lib/components/middleware/my_middleware.dart"
import 'package:revali_router/revali_router.dart';

class MyMiddleware implements Middleware {
    const MyMiddleware();

    @override
    Future<MiddlewareResult> use(MiddlwareContext context) async {
        return const MiddlewareResult.next()
    }
}
```

:::note
There's no limit to the number of middleware that can be applied to a controller or endpoint. Middleware is executed in the order they are registered.
:::

### Possible Results

The `MiddlewareResult` has two possible results: `next` and `stop`. The `next` result allows the request to continue to the next middleware or guard. The `stop` result stops the request from continuing any further in the request flow.

```dart
const MiddlewareResult.next();
```

```dart
const MiddlewareResult.stop(
    statusCode: 400,
    headers: {},
    body: 'Bad Request',
);
```

::::tip
Learn about [returning error responses][error-responses].

:::important
If the `statusCode` is not set, the default status code will be 400.
:::
::::

## Register the Middleware

To register the `Middleware`, annotate your `Middleware` class on the app, controller, or endpoint level.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyMiddleware()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

### Register as Type Reference

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Middlewares([MyMiddleware])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

:::tip
Learn about [guards].
:::

## Middleware Context

:::tip
Learn more about the Middleware Context [here][middleware-context].
:::

[error-responses]: ../lifecycle-components/overview.md#error-responses
[guards]: ./guards.md
[middleware-context]: ./middleware-context.md
