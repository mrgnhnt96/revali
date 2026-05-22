---
description: Wrap the entire request pipeline in setup and teardown logic
sidebar_position: 1
---

# Request Wrapper

A `RequestWrapper` is a Lifecycle Component that wraps the entire request pipeline. It runs setup logic before the rest of the lifecycle executes, calls `next()` to continue the pipeline, and runs teardown logic after the pipeline completes.

Request wrappers are useful when you need to establish a scope that spans middleware, guards, interceptors, and the endpoint — for example, installing a [request-scoped DI container][request-scoped-di] or propagating values through a `Zone`.

## Execution

Request wrappers are the outermost Lifecycle Component. They run before [observers][observer], [middleware][middleware], [guards][guards], and [interceptors][interceptors].

When multiple request wrappers are registered, they are nested like middleware: the first registered wrapper runs its setup first and its teardown last.

```
Wrapper A (pre)
  Wrapper B (pre)
    Observer (pre)
    Middleware → Guard → Interceptor (pre) → Endpoint → Interceptor (post)
  Wrapper B (post)
Wrapper A (post)
Observer (post)
```

:::note
Request wrappers are not applied to [WebSocket][websockets] routes.
:::

## Create a Request Wrapper

To create a `RequestWrapper`, implement the `RequestWrapper` class and implement the `wrap` method.

```dart title="lib/components/wrappers/my_wrapper.dart"
import 'package:revali_router/revali_router.dart';

class MyWrapper implements RequestWrapper {
  const MyWrapper();

  @override
  Future<Response> wrap(Context context, NextResponse next) async {
    // Setup before the pipeline runs
    try {
      return await next();
    } finally {
      // Teardown after the pipeline completes
    }
  }
}
```

The `next` callback continues the execute pipeline: middleware → guards → interceptors → handler. Always invoke `next()` unless you intend to short-circuit the request and return a response directly.

:::tip
Try using the [`create` cli][create-cli] to generate a lifecycle component scaffold that includes a `wrap` method!

```bash
dart run revali_server create lifecycle-component
```

:::

### As a Lifecycle Component

You can also define a request wrapper as a method on a [Lifecycle Component][components] class. The method must return `WrapperResult` (or `Future<Response>`) and accept a `NextResponse` parameter.

```dart title="lib/components/request_scope.dart"
import 'package:revali_router/revali_router.dart';

class RequestScope implements LifecycleComponent {
  const RequestScope();

  WrapperResult wrap(NextResponse next, DI parentDi) {
    final scoped = RequestScopedDI(parent: parentDi);

    return runZoned(
      () async {
        try {
          return await next();
        } finally {
          await scoped.dispose();
        }
      },
      zoneValues: {RequestScopedDI.zoneKey: scoped},
    );
  }
}
```

Downstream lifecycle components and endpoints can then resolve dependencies from the request scope:

```dart
final userService = RequestScopedDI.getFrom<UserService>(appDi);
```

:::tip
Learn more about [request-scoped dependencies][request-scoped-di].
:::

## Register the Request Wrapper

To register the `RequestWrapper`, annotate your class on the app, controller, or endpoint level.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@RequestScope()
@Get('')
Future<void> myEndpoint() {
    ...
}
```

### Register as Type Reference

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Wrappers([RequestScope])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

:::tip
Learn about [middleware][middleware], which runs after the request wrapper.
:::

[observer]: ../observer.md
[middleware]: ./middleware.md
[guards]: ./guards.md
[interceptors]: ./interceptors.md
[components]: ../components.md
[websockets]: ../../response/websockets.md
[create-cli]: ../../getting-started/cli.md#code-generation-made-easy
[request-scoped-di]: ../../../../revali/app-configuration/configure-dependencies.md#request-scoped-dependencies
