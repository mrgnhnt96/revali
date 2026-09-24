---
title: Writing a LifecycleComponent
description: The rules for a LifecycleComponent class - which methods become which role, what their parameters can bind, and how the constructor gets its values.
---

A `LifecycleComponent` is a class whose public methods become middleware, guards, interceptors, catchers, or request wrappers, depending on each method's return type. It is the recommended way to write lifecycle code. For when components run and where to apply them, see the [overview][overview].

<CodeFile name="lib/components/load_user.dart">

```dart
import 'package:revali_router/revali_router.dart';

class LoadUser implements LifecycleComponent {
  const LoadUser(this.users); // UserService comes from DI

  final UserService users;

  // Middleware: runs first and loads the user into request data
  Future<MiddlewareResult> load(@Header('Authorization') String? auth, Data data) async {
    if (auth != null) {
      if (await users.fromToken(auth) case final user?) {
        data.add<User>(user);
      }
    }

    return const MiddlewareResult.next();
  }

  // Guard: runs after all middleware
  GuardResult requireUser(Data data) {
    if (!data.has<User>()) {
      return const GuardResult.block(statusCode: 401, body: 'Sign in first');
    }

    return const GuardResult.pass();
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/me_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@LifecycleComponents([LoadUser])
@Controller('me')
class MeController {
  const MeController();

  @Get()
  String name(@Data() User user) => user.name;
}
```

</CodeFile>

`GET /api/me` with a valid `Authorization` header returns `200 {"data":"Ada"}`, and without one returns `401 Sign in first`. The component is applied as a type (`@LifecycleComponents([LoadUser])`) because its constructor needs a service from DI. See [Registering Components][registering].

<Callout type="tip">

`dart run revali create lifecycle-component` scaffolds a class with one method for each role. Delete the ones you don't need.

</Callout>

## Methods

Only **public, non-static** methods with one of these return types are used. Every other method is ignored, so you can keep private helpers on the class.

| Return type | Role | Async form |
| --- | --- | --- |
| `MiddlewareResult` | [Middleware][middleware] | `Future<MiddlewareResult>` |
| `GuardResult` | [Guard][guards] | `Future<GuardResult>` |
| `InterceptorPreResult` | [Interceptor (pre)][interceptors] | Mark the method `async` and keep the return type |
| `InterceptorPostResult` | [Interceptor (post)][interceptors] | Mark the method `async` and keep the return type |
| `ExceptionCatcherResult<T>` | [Exception catcher][catchers] for exceptions of type `T` | **Not supported.** Catchers must be synchronous. |
| `WrapperResult` | [Request wrapper][wrapper]. Also needs a `NextResponse` parameter. | Already a `Future<Response>` |

`InterceptorPreResult` and `InterceptorPostResult` are aliases for `FutureOr<void>`, so an interceptor returns nothing. Write the alias rather than `void`, because Revali uses the return type to recognize the role.

A class can have any number of methods, including several for the same role. They run in declaration order.

## Method Parameters

Method parameters are bound the same way as endpoint parameters:

- **Binding annotations**: `@Header()`, `@Query()`, `@Param()`, `@Body()`, `@Cookie()`, `@Data()`, `@Dep()`, and custom binds. See [Binding][binding].
- **Implied types** need no annotation: `Context`, `Request`, `Response`, `Headers`, `Data`, `MetaScope`, `Reflect`, `DI`, and more. The full list is in [Binding: Implied binding][context-bindings].
- **The exception**: in an exception catcher, a parameter of type `T` receives the exception that was thrown.
- **`NextResponse`**: in a request wrapper, it continues the rest of the pipeline.

A required binding that is missing, such as `@Header('X-Key') String key` when the header is absent, throws a `MissingArgumentException`. Revali turns that into a `400` unless a catcher handles it. Make the parameter nullable (`String? key`) when the value is optional.

<Callout type="important">

Ask for the narrowest type you need (`Request`, `Data`, `Headers`) instead of `Context`. The signature then shows what the method depends on, and the method is easier to test.

</Callout>

## Constructor Parameters

The constructor's values come from one of two places, depending on how the component is applied:

| Applied as | Constructor values come from |
| --- | --- |
| An instance: `@LoadUser(...)` | The arguments written in the annotation, which must be constants |
| A type: `@LifecycleComponents([LoadUser])` | [Dependency injection][di]. `@Dep()` is implied, so you don't write it. |

With a type reference, you can also bind request values into the constructor with binding annotations such as `@Data()` or `@Header()`. They are resolved per request:

```dart
class RequireRole implements LifecycleComponent {
  const RequireRole(this.roles, {@Data() required this.user});

  final RoleService roles; // from DI
  final User user;         // from request data

  GuardResult check() =>
      roles.isAdmin(user) ? const GuardResult.pass() : const GuardResult.block();
}
```

To mix constant configuration with a DI dependency in one annotation, see [Registering Components][registering].

## Components Are Per-Request

A new instance is created for every request, and for each role it runs in. Do not keep state in fields between method calls: the middleware and the guard of the same class do not share an instance. Pass values between methods, and between components, through [`Data`][data-sharing].

## Classic Style

The per-role pages also document the classic interfaces (`implements Middleware`, `implements Guard`, and so on), where one class has one fixed method (`use`, `protect`, ...) and receives the whole `Context`. They still work and are useful for reusable library code, but they are the advanced option. Pick one style per feature.

[overview]: /constructs/revali_server/lifecycle-components
[registering]: /constructs/revali_server/lifecycle-components#registering-components
[middleware]: /constructs/revali_server/lifecycle-components/advanced/middleware
[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[interceptors]: /constructs/revali_server/lifecycle-components/advanced/interceptors
[catchers]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[wrapper]: /constructs/revali_server/lifecycle-components/advanced/wrapper
[binding]: /constructs/revali_server/core/binding
[context-bindings]: /constructs/revali_server/core/binding#implied-binding
[data-sharing]: /constructs/revali_server/context/data-sharing
[di]: /revali/app-configuration/configure-dependencies
