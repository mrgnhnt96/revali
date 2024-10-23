# Lifecycle Components

Lifecycle components are classes that are used to manage the lifecycle of a request. Specifically, they are used to manage the request from the time it is received by the server to the time it is sent back to the client. Each can have dedicated tasks, such as logging, authentication, or authorization.

## App Lifecycle

Since Lifecycle Components are used for requests, they are called upon when a request is received by the server.

You can think of a basic request lifecycle as follows:

| Request | Middleware  |   Controller   | Endpoint | Middleware (reversed) | Response |
| :-----: | :---------: | :------------: | :------: | :-------------------: | :------: |
| Request | [ A, B, C ] | `MyController` | `hello`  |      [ C, B, A ]      | Response |

When a request is received by the server, it is passed to the middleware which performs its task. The middleware then passes the request to the controller's endpoint which will process the request and resolve the response to send. The response is then passed back to the middleware in reverse order. Finally, the response is then sent back to the client.

:::caution
"Middleware" used in this context is a general term used to describe _any_ Lifecycle Component and is not the same as the `Middleware` component used in the `revali` framework.
:::

### Exceptions

If an exception is thrown during the request lifecycle, the flow will be aborted and the exception will be caught by the server. The server will then send an error response back to the client.

:::tip
You can catch exceptions by using the [`Catcher`][catchers] Lifecycle Component.
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

Lifecycle components can be applied at different levels of the application: app, controller, and endpoint. By applying Lifecycle Components at different levels, you can control when the Lifecycle Component gets executed.

### App Level

To apply a Lifecycle Component to the entire application, you can annotate the app with the Lifecycle Component.

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

To apply a Lifecycle Component to a specific controller, you can annotate the controller with the Lifecycle Component.

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

To apply a Lifecycle Component to a specific endpoint, you can annotate the endpoint with the Lifecycle Component.

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
The order of the annotations between Lifecycle Components and non-Lifecycle Components does not matter.
:::

## Order of Execution

The order of execution of Lifecycle Components is important. When a request is received by the server, the middleware is executed in the order that they are applied. The controller is then executed, followed by the endpoint. The response is then passed back to the middleware in reverse order. Understanding the order of execution of Lifecycle Components is important when designing your application.

If we have multiple Lifecycle Components applied to an endpoint, the order of execution is from top to bottom.

```dart title="routes/apps/my_app.dart"
@LifecycleComponent0()
@App()
class MyApp extends AppConfig {
    ...
}
```

```dart title="routes/controllers/my_controller.dart"
@LifecycleComponentA()
@Controller('')
class MyController {

    @Get()
    @LifecycleComponentB()
    @LifecycleComponentC()
    String hello() {
        return 'world';
    }
}
```

In the example above, the order of Lifecycle Component execution is as follows:

1. `LifecycleComponent0`
2. `LifecycleComponentA`
3. `LifecycleComponentB`
4. `LifecycleComponentC`
5. -- endpoint --
6. `LifecycleComponentC`
7. `LifecycleComponentB`
8. `LifecycleComponentA`
9. `LifecycleComponent0`

## Error Responses

Some Lifecycle Components are responsible for returning error responses. Such components include `ExceptionCatcher`, `Guard`, and `Middleware`.

Typically, a Lifecycle Component that can return an error response can accept a `statusCode`, `headers`, and `body`. The status code and body values passed to the method will override any values previously set by the request flow, while the headers will be merged with the headers set by the request flow.

### Debug Mode

When an error response is returned in [debug mode][debug-mode], a stack trace will be included in the error response.

Depending on the response content type, the stack trace will be formatted differently.

:::tip
Learn more about [run modes][run-modes].
:::

#### String Debug Message

```dart
body: 'An error occurred',
```

```plaintext
An error occurred

__DEBUG__:
Error: Instance of 'MyException'

Stack Trace:
routes/hello_controller.dart 13:5                            HelloController.hello
.revali/server/routes/__hello.dart 15:16                     hello.<fn>
package:revali_router/src/router/execute.dart 56:22          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 54:11          Execute.run
package:revali_router/src/router/router.dart 159:22          Router.handle
package:revali_router/src/server/handle_requests.dart 23:20  handleRequests
```

#### Map Debug Message

```dart
body: {
  'message': 'An error occurred',
},
```

```json
{
    "message": "An error occurred",
    "__DEBUG__": {
        "error": "Instance of 'MyException'",
        "stackTrace": [
            "routes/hello_controller.dart 13:5                            HelloController.hello",
            ".revali/server/routes/__hello.dart 15:16                     hello.<fn>",
            "package:revali_router/src/router/execute.dart 56:22          Execute.run.<fn>",
            "dart:async                                                   runZonedGuarded",
            "package:revali_router/src/router/execute.dart 54:11          Execute.run",
            "package:revali_router/src/router/router.dart 159:22          Router.handle",
            "package:revali_router/src/server/handle_requests.dart 23:20  handleRequests"
        ]
    }
}
```

#### List Debug Message

```dart
body: [
  'An error occurred',
],
```

```json
[
    "An error occurred",
    {
        "__DEBUG__": {
            "error": "Instance of 'MyException'",
            "stackTrace": [
                "routes/hello_controller.dart 13:5                            HelloController.hello",
                ".revali/server/routes/__hello.dart 15:16                     hello.<fn>",
                "package:revali_router/src/router/execute.dart 56:22          Execute.run.<fn>",
                "dart:async                                                   runZonedGuarded",
                "package:revali_router/src/router/execute.dart 54:11          Execute.run",
                "package:revali_router/src/router/router.dart 159:22          Router.handle",
                "package:revali_router/src/server/handle_requests.dart 23:20  handleRequests"
            ]
        }
    }
]
```

### Profile Mode

When an error response is return in profile mode, the error response will not include any debug messages;

:::note
Profile mode is only available for the [`build`][build-command] command.
:::

### Release Mode

When an error response is returned in release mode, the error response will not include any debug messages.

[catchers]: ./6-exception-catchers.md
[debug-mode]: ../../../revali/cli/00-dev.md#debug-mode
[run-modes]: ../../../revali/cli/00-dev.md#run-modes
[build-command]: ../../../revali/cli/10-build.md
