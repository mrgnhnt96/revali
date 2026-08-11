---
title: Middleware
description: React to incoming requests by modifying the request context
---

A `Middleware` is a Lifecycle Component that is used to modify the request or response before it reaches the endpoint.

Middleware is useful for binding data to the request context, transforming the request or response, and other tasks that need to be executed before the guard or endpoint.

## Execution

Middleware is executed before the guards, in the order they are registered.

## Create a Middleware

To create a `Middleware`, you need to implement the `Middleware` class and implement the `use` method.

<CodeFile name="lib/components/middleware/my_middleware.dart">

```dart
import 'package:revali_router/revali_router.dart';

class MyMiddleware implements Middleware {
    const MyMiddleware();

    @override
    Future<MiddlewareResult> use(Context context) async {
        return const MiddlewareResult.next();
    }
}
```

</CodeFile>

<Callout type="note">

There's no limit to the number of middleware that can be applied to a controller or endpoint. Middleware is executed in the order they are registered.

</Callout>

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

<Callout type="tip">

Learn about [returning error responses][error-responses].

<Callout type="important">

If the `statusCode` is not set, the default status code will be 400.

</Callout>

</Callout>

## Register the Middleware

To register the `Middleware`, annotate your `Middleware` class on the app, controller, or endpoint level.

<CodeFile name="routes/controllers/my_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyMiddleware()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

</CodeFile>

### Register as Type Reference

<CodeFile name="routes/controllers/my_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Middlewares([MyMiddleware])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

</CodeFile>

<Callout type="tip">

Learn about [guards].

</Callout>

[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
