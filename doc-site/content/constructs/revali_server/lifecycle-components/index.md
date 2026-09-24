---
title: Overview
description: Run code before and after your endpoints - authentication, logging, data loading, error handling - and control where it applies.
---

Lifecycle components are classes that run around your endpoints: they can load data, reject a request, change the response, or turn an exception into an error response. Use them for anything that applies to more than one endpoint, such as authentication, request logging, or error mapping.

This page owns the parts every component shares: the order they run in, where you can apply them, how to register them, and how their error responses are formed. The pages for each role only cover that role.

## Quick Example

Write a class that implements `LifecycleComponent`. Each method's **return type** decides its role: this one returns `GuardResult`, so it runs as a [guard][guards].

<CodeFile name="lib/components/api_key.dart">

```dart
import 'package:revali_router/revali_router.dart';

class ApiKey implements LifecycleComponent {
  const ApiKey();

  GuardResult check(@Header('X-Api-Key') String? key) {
    if (key != 'secret') {
      return const GuardResult.block(statusCode: 401, body: 'Invalid API key');
    }

    return const GuardResult.pass();
  }
}
```

</CodeFile>

Apply it by using the class as an annotation:

<CodeFile name="routes/controllers/reports_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';
import 'package:my_app/components/api_key.dart';

@ApiKey()
@Controller('reports')
class ReportsController {
  const ReportsController();

  @Get()
  List<String> list() => ['q1', 'q2'];
}
```

</CodeFile>

```bash
curl -H 'X-Api-Key: secret' http://localhost:8080/api/reports
# 200 {"data":["q1","q2"]}

curl http://localhost:8080/api/reports
# 401 Invalid API key
```

In [debug mode](#debug-and-release-mode) the `401` body also carries a `__DEBUG__` block with the stack trace.

<Callout type="tip">

Scaffold a component with `dart run revali create lifecycle-component`. See [Writing a LifecycleComponent][components] for constructor arguments, parameter binding, and the full set of rules.

</Callout>

## Roles

| Return type | Role | Runs | Can stop the request? |
| --- | --- | --- | --- |
| `WrapperResult` (with a `NextResponse` parameter) | [Request wrapper][wrapper] | Around everything below | Yes, by not calling `next()` |
| `MiddlewareResult` | [Middleware][middleware] | Before guards | Yes: `MiddlewareResult.stop()` (400) |
| `GuardResult` | [Guard][guards] | After middleware | Yes: `GuardResult.block()` (403) |
| `InterceptorPreResult` | [Interceptor (pre)][interceptors] | After guards, before the endpoint | Only by throwing |
| `InterceptorPostResult` | [Interceptor (post)][interceptors] | After the endpoint | Only by throwing |
| `ExceptionCatcherResult<T>` | [Exception catcher][catchers] | When an exception of type `T` is thrown | Produces the error response |

Two more pieces plug into the lifecycle but are not `LifecycleComponent` methods:

- [Observers][observer] watch every request and cannot change it. App level only.
- [Response handlers][response-handler] replace how the final response is written to the socket.

### Built-in Kits

| Kit | What it does |
| --- | --- |
| `@RequestId()` | Sets `X-Request-Id` on the response to the request's [trace id][tracing]: the incoming `X-Request-Id` if the caller sent one, otherwise a generated id. Pass a name to use another header: `@RequestId('X-Correlation-Id')`. |
| [`@Throttle(...)`][throttle] | Rate-limits callers with `429 Too Many Requests`. |
| [`@AllowOrigins(...)`][allow-origins] | CORS allowed origins. This is an access-control annotation, not a lifecycle component. |

## Lifecycle Order

For a request that matches a route, Revali runs these steps in order:

1. **Access control**: [`@AllowOrigins`][allow-origins], [`@ExpectHeaders`][expect-headers], and [`@PreventHeaders`][prevent-headers] are checked. A failure returns `403`.
2. **OPTIONS requests** return here with `200` and the CORS headers. No components run.
3. **Redirects** declared on the endpoint return here.
4. **Request wrappers**: setup, outermost first.
5. **Observers** are notified. They are not awaited.
6. **Middleware**
7. **Guards**
8. **Interceptors (pre)**
9. **Pipes and binding**, then **the endpoint**. An automatic `HEAD` request skips the endpoint.
10. **Interceptors (post)**, in reverse order
11. **Request wrappers**: teardown, innermost first.
12. The **response handler** writes the response.

```mermaid
graph LR;
    A[Access control] --> B[Wrapper setup]
    B --> C[Middleware]
    C --> D[Guards]
    D --> E[Interceptors pre]
    E --> F[Endpoint]
    F --> G[Interceptors post]
    G --> H[Wrapper teardown]
    H --> I[Response]
```

- A middleware `stop` or a guard `block` ends the request immediately. Later steps, including the post interceptors, do not run.
- An exception thrown anywhere from step 4 to step 11 goes to the [exception catchers][catchers]. The post interceptors do not run for that request.
- Only `Exception` subtypes reach catchers. An `Error` (such as a `TypeError`) always becomes a `500`.
- [WebSocket][websockets] routes skip request wrappers and interceptors.

## Scoping

You can apply a component to the app, a controller, or a single endpoint.

| Where you annotate | Applies to |
| --- | --- |
| The `@App()` class | Every request the app handles |
| A `@Controller()` class | Every endpoint in that controller |
| An endpoint method | Only that endpoint |

<CodeFile name="routes/apps/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@RequestId()
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);
}
```

</CodeFile>

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@ApiKey()
@Controller('users')
class UsersController {
  const UsersController();

  @Throttle(max: 10)
  @Get(':id')
  String get(@Param() String id) => id;
}
```

</CodeFile>

All three apply to `GET /api/users/1`. The [lifecycle order](#lifecycle-order) comes first, and scope only orders components within the same role. `ApiKey` and `Throttle` are both guards, so they run in that order. `RequestId` is a pre-interceptor, so it runs after both guards even though it is declared on the app. The position of lifecycle annotations relative to `@Get`, `@Controller`, or `@App` does not matter.

### Order of Execution

Components are collected from the outside in: **app, then controller, then endpoint**. Within one declaration they run in the order the annotations are written. Each role keeps this order, and only the unwinding steps reverse it.

```dart
@A()
@App()
final class MyApp extends AppConfig { /* ... */ }

@B()
@Controller('things')
class MyController {
  @C()
  @D()
  @Get()
  String hello() => 'world';
}
```

| Role | Order for `GET /api/things` |
| --- | --- |
| Wrappers (setup), middleware, guards, interceptors (pre) | `A`, `B`, `C`, `D` |
| Interceptors (post), wrappers (teardown) | `D`, `C`, `B`, `A` |
| Exception catchers | `C`, `D`, `B`, `A`: endpoint first, then controller, then app. The first catcher that handles the exception wins, and a `DefaultExceptionCatcher` is always tried last. |

<Callout type="note">

Source order holds only within one style. If one declaration mixes styles, each role runs classic instances first (`@MyGuard()` on a class that `implements Guard`), then classic components applied by type (`@Guards([MyGuard])`), then `LifecycleComponent`s, whatever order the annotations are written in. Use one style per feature and this never comes up.

</Callout>

## Registering Components

There are two ways to apply a component.

**As an instance**: `@ApiKey()`. The arguments you pass are compile-time constants, which is what Dart requires of every annotation. Literals, `const` constructors, and `const` variables all work, but `@Audit(Logger())` does not unless `Logger` has a `const` constructor.

**As a type**: `@LifecycleComponents([ApiKey, Audit])`. Revali creates the component for each request and resolves every constructor parameter from [dependency injection][di]. Use this when the constructor needs a service that can't be constant:

```dart
class Audit implements LifecycleComponent {
  const Audit(this.log); // AuditLog is resolved from DI

  final AuditLog log;

  InterceptorPostResult record(Request request) {
    log.write('${request.method} ${request.uri}');
  }
}

@LifecycleComponents([Audit])
@Get()
String hello() => 'world';
```

To pass constant configuration **and** a runtime dependency in one annotation, pass an [`Inject` marker][inject] in place of the dependency. For example, `@Audit(InjectAuditLog())`, where `InjectAuditLog extends Inject implements AuditLog`, and Revali resolves the real `AuditLog` from DI.

### Classic Components

Classes that implement the classic interfaces (`Middleware`, `Guard`, `Interceptor`, `RequestWrapper`, `ExceptionCatcher`, `Observer`) are applied the same way: as an instance (`@MyGuard()`), or by type with the annotation for their role.

| Role | Type annotation |
| --- | --- |
| `Middleware` | `@Middlewares([MyMiddleware])` |
| `Guard` | `@Guards([MyGuard])` |
| `Interceptor` | `@Intercepts([MyInterceptor])` |
| `RequestWrapper` | `@Wrappers([MyWrapper])` |
| `ExceptionCatcher` | `@Catches([MyCatcher])` |
| `Observer` (app only) | `@Observers([MyObserver])` |
| `CombineComponents` | `@Combines([MyGroup])` |

`CombineComponents` bundles several classic components under one annotation. A `LifecycleComponent` already groups its roles in one class, so you only need this for classic components:

<CodeFile name="lib/components/auth_components.dart">

```dart
import 'package:revali_router/revali_router.dart';

class AuthComponents implements CombineComponents {
  const AuthComponents();

  @override
  List<Middleware> get middlewares => const [AuthMiddleware()];

  @override
  List<Guard> get guards => const [AuthGuard()];

  @override
  List<Interceptor> get interceptors => const [];

  @override
  List<RequestWrapper> get requestWrappers => const [];

  @override
  List<ExceptionCatcher> get catchers => const [AuthExceptionCatcher()];
}
```

</CodeFile>

Apply it with `@AuthComponents()`, or with `@Combines([AuthComponents])` when its constructor needs dependencies.

## Error Responses

Middleware (`stop`), guards (`block`), and exception catchers (`handled`) all accept the same three optional arguments:

| Argument | Effect |
| --- | --- |
| `statusCode` | Replaces the status code. Falls back to the role's default when omitted. |
| `headers` | Merged into the headers already set on the response. |
| `body` | Replaces the body. When omitted, the body already on the response is kept. |

| Result | Default status |
| --- | --- |
| `MiddlewareResult.stop()` | `400` |
| `GuardResult.block()` | `403` |
| `ExceptionCatcherResult.handled()` | `500`, or `400` for a `MissingArgumentException` |
| An exception no catcher handles | `500 Internal Server Error`, `400 Bad Request` for a `MissingArgumentException`, or the status and envelope of an [`HttpError`][http-error] |

To change the framework's default bodies (`Internal Server Error`, `Not Found`, and so on), see [Default Responses][default-responses].

### Debug and Release Mode

In [debug mode][run-modes] (the default for `revali dev`), error responses include a `__DEBUG__` section with the error and stack trace. How it is added depends on the body:

| Body | Debug output |
| --- | --- |
| String | `__DEBUG__:`, `Error:`, and `Stack Trace:` lines appended to the text |
| Map | A `"__DEBUG__": {"error": ..., "stackTrace": [...]}` key added to the object |
| List | A `{"__DEBUG__": {...}}` element appended to the list |

For example, a guard that blocks with `body: 'I am a custom rejection message'` responds in debug mode with:

```text
I am a custom rejection message

__DEBUG__:
Error: GuardStopException: RejectGuard

Stack Trace:
package:revali_router/src/router/run_guards.dart ...
```

In release and profile builds (`revali build`), no debug details are added:

- A response that you wrote (you passed a `statusCode`, `headers`, or `body`) is sent exactly as written, even if it is a `5xx`.
- Any other `5xx` is replaced by the default `500 Internal Server Error` response, so internal details don't leak.

[components]: /constructs/revali_server/lifecycle-components/components
[wrapper]: /constructs/revali_server/lifecycle-components/advanced/wrapper
[middleware]: /constructs/revali_server/lifecycle-components/advanced/middleware
[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[interceptors]: /constructs/revali_server/lifecycle-components/advanced/interceptors
[catchers]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[response-handler]: /constructs/revali_server/lifecycle-components/advanced/response-handler
[observer]: /constructs/revali_server/lifecycle-components/observer
[throttle]: /constructs/revali_server/lifecycle-components/kits/throttle
[allow-origins]: /constructs/revali_server/access-control/allow-origins
[expect-headers]: /constructs/revali_server/access-control/expect-headers
[prevent-headers]: /constructs/revali_server/access-control/prevent-headers
[websockets]: /constructs/revali_server/response/websockets
[tracing]: /revali/app-configuration/tracing
[di]: /revali/app-configuration/configure-dependencies
[inject]: /revali/app-configuration/configure-dependencies#the-inject-marker-class
[http-error]: /revali/app-configuration/default-responses#httperror
[default-responses]: /revali/app-configuration/default-responses
[run-modes]: /revali/cli/dev#run-modes
