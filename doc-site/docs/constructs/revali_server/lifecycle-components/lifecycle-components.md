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

:::info
There are different types of lifecycle components that will be discussed in the following sections.
:::

### Exceptions

If an exception is thrown during the request lifecycle, the flow will be aborted and the exception will be caught by the server. The server will then send an error response back to the client.

:::tip
You can catch exceptions by using the [`Catcher`](./catchers) lifecycle component.
:::

## Inheritance

Let's say that we want to print a timestamp to the console every time a request is received by the server. One way we can do this is by creating a `Middleware` class.

```dart title="lib/middlewares/timestamp.dart"
class Timestamp implements Middleware {
    const Timestamp();

    Future<MiddlewareResult> use(context, action)  async {
        print(DateTime.now());

        return action.next();
    }
}
```

If we wanted to apply this to a specific endpoint, we could do so by adding `Timestamp` as an annotation to the endpoint.

```dart title="routes/controllers/my_controller.dart"
@Controller('')
class MyController {

    @Get()
    // highlight-next-line
    @Timestamp()
    String hello() {
        return 'world';
    }
}
```

:::note
The order of the annotations between lifecycle component annotations and non-lifecycle component annotations does not matter.
:::

If wanted to apply the `Timestamp` middleware to all endpoints in the `MyController` controller, we can apply the `Timestamp` middleware to the `MyController` class.

```dart title="routes/controllers/my_controller.dart"
// highlight-next-line
@Timestamp()
@Controller('')
class MyController {

    @Get()
    String hello() {
        return 'world';
    }
}
```

Lastly, if we wanted to apply the `Timestamp` middleware to all endpoints in the `MyApp` App, we can apply the `Timestamp` middleware to the `MyApp` class.

```dart title="routes/apps/my_app.dart"
// highlight-next-line
@Timestamp()
@App()
class MyApp extends AppConfig {
    ...
}
```

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
