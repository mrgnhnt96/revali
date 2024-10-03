---
title: Lifecycle Components
---

# Overview

Lifecycle components are classes that are used to manage the lifecycle of a request. Specifically, they are used to manage the request from the time it is received by the server to the time it is sent back to the client. Each can have dedicated tasks, such as logging, authentication, and authorization.

## App Lifecycle

Since lifecycle components are used for requests, they are called upon when a request is received by the server.

You can think of a basic request lifecycle as follows:

| Request | Middleware | Controller | Endpoint | Middleware (reversed) | Response |
| :-: | :-: | :-: | :-: | :-: | :-: |
| Request | [ A, B, C ]  | `MyController` | `hello` | [ C, B, A ] | Response |

When a request is received by the server, it is passed to the middleware which will performs it's task. The middleware then passes the request to the controller's endpoint which will process the request and resolve the response to send. The response is then passed back to the middleware in reverse order. Finally, the response is then sent back to the client.

:::caution
"Middleware" used in this context is a general term used to describe lifecycle components and is not the same as the `Middleware` component used in the `revali` framework.
:::

### Exceptions

If an exception is thrown during the request lifecycle, the flow will be aborted and the exception will be caught by the server. The server will then send an error response back to the client.

:::tip
You can catch exceptions by using the [`Catcher`](./catchers) lifecycle component.
:::

## Lifecycle Order

1. Request
1. Observer
1. Middleware
1. Guard
1. Interceptor (Pre)
1. Endpoint
1. Interceptor (Post)
1. Observer
1. Response

## Scoping

Lifecycle components can be applied at different levels of the application. They can be applied at the app, controller, or endpoint level. By applying lifecycle components at different levels, you can control where the lifecycle component is or isn't applied.

### App Level

To apply a lifecycle component to the entire application, you can annotate the app with the lifecycle component.

```dart title="routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyLifecycleComponent()
@App()
class MyApp extends AppConfig {
    ...
}
```

:::info
The `MyLifecycleComponent` will be applied to all requests received by the server.
:::

### Controller Level

To apply a lifecycle component to a specific controller, you can annotate the controller with the lifecycle component.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyLifecycleComponent()
@Controller('')
class MyController {
    ...
}
```

:::info
The `MyLifecycleComponent` will only be applied to requests received by the `MyController` controller.
:::

### Endpoint Level

To apply a lifecycle component to a specific endpoint, you can annotate the endpoint with the lifecycle component.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('')
class MyController {
    ...

    @Get()
    // highlight-next-line
    @MyLifecycleComponent()
    String hello() {
        return 'world';
    }
}
```

:::info
The `MyLifecycleComponent` will only be applied to requests received by the `hello` endpoint.
:::

:::note
The order of the annotations between lifecycle component annotations and non-lifecycle component annotations does not matter.
:::

## Order of Execution

The order of execution of lifecycle components is important. When a request is received by the server, the middleware is executed in the order that they are applied. The controller is then executed, followed by the endpoint. The response is then passed back to the middleware in reverse order. Understanding the order of execution of lifecycle components is important when designing your application.

If we have multiple lifecycle components applied to an endpoint, the order of execution is from top to bottom.

```dart title="routes/apps/my_app.dart"
@Middleware0()
@App()
class MyApp extends AppConfig {
    ...
}
```

```dart title="routes/controllers/my_controller.dart"
@MiddlewareA()
@Controller('')
class MyController {

    @Get()
    @MiddlewareB()
    @MiddlewareC()
    String hello() {
        return 'world';
    }
}
```

In the example above, the order of middleware execution is as follows:

1. `Middleware0`
2. `MiddlewareA`
3. `MiddlewareB`
4. `MiddlewareC`
5. -- endpoint --
6. `MiddlewareC`
7. `MiddlewareB`
8. `MiddlewareA`
9. `Middleware0`
