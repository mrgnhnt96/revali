---
description: Manipulate the request & response
sidebar_position: 4
---

# Interceptors

An `Interceptor` is a Lifecycle Component that can be used to modify the request or response before or after the request is processed by the controller or endpoint.

Interceptors are useful for binding data to the request context, transforming the request or response, and other tasks that need to be executed before or after the endpoint.

## Execution

Interceptors are executed in two phases:

### Pre

The `pre` method is executed after the Guards and before the endpoint.

### Post

The `post` method is executed after the endpoint and before the response is returned.

### Order of Execution

Interceptors are executed in the order they are registered. Before the endpoint is executed, all pre-interceptors are executed. After the endpoint is executed, all post-interceptors are executed in the reverse order.

1. Interceptor 1 (pre)
2. Interceptor 2 (pre)
3. Endpoint
4. Interceptor 2 (post)
5. Interceptor 1 (post)

## Create an Interceptor

To create an `Interceptor`, you need to implement the `Interceptor` class and implement the `pre` and `post` methods.

```dart title="lib/components/interceptors/my_interceptor.dart"
import 'package:revali_router/revali_router.dart';

class MyInterceptor implements Interceptor {
    const MyInterceptor();

    @override
    Future<void> pre(context) async {}

    @override
    Future<void> post(context) async {}
}
```

:::note
There's no limit to the number of interceptors that can be applied to a controller or endpoint. Interceptors are executed in the order they are registered.
:::

## Register the Interceptor

To register the `Interceptor`, annotate your `Interceptor` class on the app, controller, or endpoint level.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyInterceptor()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `Interceptor` as a type reference using the `@Intercepts()` annotation.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Intercepts([MyInterceptor])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

:::tip
Learn more about [type referencing][type-referencing].
:::

## Interceptor Context

:::tip
Learn more about the Interceptor Context [here][interceptor-context].
:::

[type-referencing]: ../tidbits.md#using-types-in-annotations
[interceptor-context]: ./interceptor-context.md
