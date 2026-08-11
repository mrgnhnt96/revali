---
title: Request Wrapper
description: Wrap the entire request pipeline in setup and teardown logic
---

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

<Callout type="note">

Request wrappers are not applied to [WebSocket][websockets] routes.

</Callout>

## Create a Request Wrapper

To create a `RequestWrapper`, implement the `RequestWrapper` class and implement the `wrap` method.

<CodeFile name="lib/components/wrappers/my_wrapper.dart">

```dart
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

</CodeFile>

The `next` callback continues the execute pipeline: middleware → guards → interceptors → handler. Always invoke `next()` unless you intend to short-circuit the request and return a response directly.

<Callout type="tip">

Try using the [`create` cli][create-cli] to generate a lifecycle component scaffold that includes a `wrap` method!

```bash
dart run revali create lifecycle-component
```

</Callout>

### As a Lifecycle Component

You can also define a request wrapper as a method on a [Lifecycle Component][components] class. The method must return `WrapperResult` (or `Future<Response>`) and accept a `NextResponse` parameter.

<CodeFile name="lib/components/request_scope.dart">

```dart
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

</CodeFile>

Downstream lifecycle components and endpoints can then resolve dependencies from the request scope:

```dart
final userService = RequestScopedDI.getFrom<UserService>(appDi);
```

<Callout type="tip">

Learn more about [request-scoped dependencies][request-scoped-di].

</Callout>

## Register the Request Wrapper

To register the `RequestWrapper`, annotate your class on the app, controller, or endpoint level.

<CodeFile name="routes/controllers/my_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@RequestScope()
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
@Wrappers([RequestScope])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

</CodeFile>

<Callout type="tip">

Learn about [middleware][middleware], which runs after the request wrapper.

</Callout>

[observer]: /constructs/revali_server/lifecycle-components/observer
[middleware]: /constructs/revali_server/lifecycle-components/advanced/middleware
[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[interceptors]: /constructs/revali_server/lifecycle-components/advanced/interceptors
[components]: /constructs/revali_server/lifecycle-components/components
[websockets]: /constructs/revali_server/response/websockets
[create-cli]: /constructs/revali_server/getting-started/cli#code-generation-made-easy
[request-scoped-di]: /revali/app-configuration/configure-dependencies#request-scoped-dependencies
