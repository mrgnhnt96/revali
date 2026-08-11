---
title: Components
---

Similar to creating a controller and endpoints using a class and methods, you can create lifecycle components. By using a class, you can group related lifecycle components together and reuse them across different controllers/endpoints.

Components are short-lived classes. They are created when the server is executing a particular piece of middleware, and they are destroyed when the middleware is done executing. New instances of the component are created for each request.

<Callout type="warning">

You may be tempted to "share" data between method calls by storing it in a component. Not only is this **NOT recommended**, but it is very likely to cause **bugs** 🐛 in your application.

</Callout>

## Group Lifecycle Components

To create a group of lifecycle components, create a class that implements the `LifecycleComponent` class.

<CodeFile name="lib/components/my_component.dart">

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();
}
```

</CodeFile>

<Callout type="tip">

Try using the [`create` cli][create-cli] to generate the components for you!

```bash
dart run revali create lifecycle-component
```

</Callout>

You may add fields to this class as you need, such as classes from your [dependencies][di] or values that are specific to the component. You can use [binding annotations][binding] to inject these dependencies into the component.

<CodeFile name="lib/components/my_component.dart">

```dart
import 'package:revali_router/revali_router.dart';

class MyComponent implements LifecycleComponent {
  const MyComponent(
    this.myService, {
        @Data() required this.role,
    });

  final MyService myService;
  final Role role;
}
```

</CodeFile>

<Callout type="note">

The `@Dep` annotation (used to retrieve data from your [dependencies][di]) is assumed for parameters in the constructor of a `LifecycleComponent`. This means that you do not need to add the `@Dep` annotation. All other annotations, such as `@Data`, etc. must be added to the constructor parameters.

</Callout>

<Callout type="tip">

Learn more about the [data handler][data-sharing]

</Callout>

## Define a Lifecycle Component

Now that you have a class to group your lifecycle components, you can create a lifecycle component by adding methods to the class. The method's return type is what determines which lifecycle component it associated with.

| Return Type                         | Lifecycle Type                         | `Future` Support |
| ----------------------------------- | -------------------------------------- | ---------------- |
| `WrapperResult`                     | [Request Wrapper][wrapper]             | ✅               |
| `GuardResult`                       | [Guard][guard]                         | ✅               |
| `MiddlewareResult`                  | [Middleware][middleware]               | ✅               |
| `InterceptorPreResult`              | [Interceptor (pre)][interceptor-pre]   | ✅               |
| `InterceptorPostResult`             | [Interceptor (post)][interceptor-post] | ✅               |
| `ExceptionCatcherResult<Exception>` | [Exception Catcher][exception-catcher] | ❌               |

<CodeFile name="lib/components/my_component.dart">

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

   GuardResult getAuth() {
    // Perform authentication logic
  }

  Future<MiddlewareResult> getRole() async {
    // Get role logic
  }

  Future<GuardResult> verifyRole() async {
    // Perform role verification logic
  }
}
```

</CodeFile>

<Callout type="tip">

You can define as many lifecycle components as you need in a single class.

</Callout>

### Binding

Similar in endpoints, you can [bind][binding] values to the parameters of the lifecycle component methods. Values such as the request, context, dependencies, or other lifecycle components.

<CodeFile name="lib/components/my_component.dart">

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  GuardResult getAuth(@Body() Map<String, dynamic> body) {
    // Perform authentication logic
  }

  Future<GuardResult> verifyRole(@Param('id', UserPipe) User user) async {
    // Perform role verification logic
  }
}
```

</CodeFile>

### Context

Every Lifecycle Component method has access to the same [`Context`][context], regardless of its role (Guard, Middleware, Interceptor, Exception Catcher, or Request Wrapper). There isn't a different context type per role -- `Context` exposes `data`, `meta`, `route`, `request`, `response`, and `reflect`, and each of those fields can be [bound implicitly][implied-binding] as its own parameter, so you don't need to add an annotation to bind it:

<CodeFile name="lib/components/my_component.dart">

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  GuardResult getAuth(Data data) {
    final user = data.get<User>();

    if (user == null) {
      return const GuardResult.block(statusCode: 401);
    }

    return const GuardResult.pass();
  }

  Future<GuardResult> verifyRole(Request request) async {
    // Perform role verification logic using request.pathParameters, etc.
    return const GuardResult.pass();
  }
}
```

</CodeFile>

---

In addition to the [base implied bindings][binding], here's a comprehensive list of the implicit bindings available to every Lifecycle Component method:

| Implicit Binding      | Resolves To                                 |
| --------------------- | -------------------------------------------- |
| `Context`             | The full context                             |
| `DI`                  | The app's dependency injection container     |
| `Request`             | `context.request`                            |
| `RequestHeaders`      | `context.request.headers`                    |
| `RequestCookies`      | `context.request.headers.cookies`            |
| `Response`            | `context.response`                           |
| `Headers`             | `context.response.headers`                   |
| `ResponseHeaders`     | `context.response.headers`                   |
| `Cookies`             | `context.response.headers.cookies`           |
| `ResponseCookies`     | `context.response.headers.cookies`           |
| `SetCookies`          | `context.response.headers.setCookies`        |
| `Body` / `PayloadBody`| `context.response.body`                      |
| `Meta` / `MetaScope`  | `context.meta`                               |
| `RouteEntry`          | `context.route`                              |
| `Data`                | `context.data` (see [Data Sharing][data-sharing]) |
| `Reflect`             | `context.reflect`                            |
| `CleanUp`             | A cleanup handle sourced from `context.data` |

`NextResponse` is the one binding that **is** role-specific: a parameter typed `NextResponse` is what marks a method as a [Request Wrapper][wrapper] (its return type must be `WrapperResult`).

<Callout type="important">

While you can bind the context object itself, it is recommended to scope your needs as much as possible. This can help declare your intent and make your code more readable. Consequently, it can also help you test your code more effectively.

</Callout>

## Register the Lifecycle Component

To register the lifecycle component, annotate your `LifecycleComponent` class on the app, controller, or endpoint level.

<CodeFile name="routes/controllers/my_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyComponent()
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
@LifecycleComponents([MyComponent])
@Get('')
Future<void> myEndpoint() {
    ...
}
```

</CodeFile>

[di]: /revali/app-configuration/configure-dependencies
[binding]: /constructs/revali_server/core/binding
[data-sharing]: /constructs/revali_server/context/data-sharing
[wrapper]: /constructs/revali_server/lifecycle-components/advanced/wrapper
[context]: /constructs/revali_server/context
[guard]: /constructs/revali_server/lifecycle-components/advanced/guards
[middleware]: /constructs/revali_server/lifecycle-components/advanced/middleware
[interceptor-pre]: /constructs/revali_server/lifecycle-components/advanced/interceptors#pre
[interceptor-post]: /constructs/revali_server/lifecycle-components/advanced/interceptors#post
[exception-catcher]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[implied-binding]: /constructs/revali_server/core/implied_binding
[create-cli]: /constructs/revali_server/getting-started/cli#code-generation-made-easy
