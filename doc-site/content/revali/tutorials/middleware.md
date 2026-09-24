---
title: Middleware and Guards
description: Log every request with middleware, and protect endpoints with a bearer-token guard
---

In this tutorial you build two [lifecycle components][lifecycle-component]: a middleware that logs each request, and a guard that blocks requests without a valid bearer token. A method's return type decides its role. A method that returns `MiddlewareResult` is middleware and runs first. A method that returns `GuardResult` is a guard: it runs next and either lets the request through or blocks it.

## 1. Log Every Request (Middleware)

<CodeFile name="lib/components/request_logger.dart">

```dart
import 'package:revali_router/revali_router.dart';

class RequestLogger implements LifecycleComponent {
  const RequestLogger();

  MiddlewareResult logRequest(Request request) {
    print('[${request.method}] ${request.uri.path}');

    return const MiddlewareResult.next();
  }
}
```

</CodeFile>

To apply a component, use it as an annotation on an endpoint, a controller or the app:

<CodeFile name="routes/controllers/some_controller.dart">

```dart
import 'package:my_app/components/request_logger.dart';
import 'package:revali_router/revali_router.dart';

@Controller('some')
class SomeController {
  const SomeController();

  @RequestLogger()
  @Get('logged')
  String logged() => 'logged';
}
```

</CodeFile>

`GET /api/some/logged` prints `[GET] /api/some/logged` and returns `{"data": "logged"}`.

Middleware can also end a request early with `MiddlewareResult.stop(statusCode: …, body: …)`, or pass values to the endpoint with [`Data`][data-sharing]. The guard below does both.

## 2. Require a Bearer Token (Guard)

<CodeFile name="lib/components/require_auth.dart">

```dart
import 'package:revali_router/revali_router.dart';

class RequireAuth implements LifecycleComponent {
  const RequireAuth();

  GuardResult checkAuth(
    @Header('Authorization') String? authorization,
    Data data,
  ) {
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return const GuardResult.block(
        statusCode: 401,
        body: 'Missing or invalid Authorization header',
      );
    }

    final token = authorization.substring('Bearer '.length);

    if (!isValidToken(token)) {
      return const GuardResult.block(statusCode: 401, body: 'Invalid token');
    }

    data.add(token); // the endpoint reads this with @Data()
    return const GuardResult.pass();
  }
}

// Replace with a lookup against your auth provider.
bool isValidToken(String token) => token == 'secret-token';
```

</CodeFile>

In a real app, inject an auth service with `@Dep() AuthService auth` as another parameter of `checkAuth`, and register the service in [`configureDependencies`][configure-dependencies].

<CodeFile name="routes/controllers/account_controller.dart">

```dart
import 'package:my_app/components/require_auth.dart';
import 'package:revali_router/revali_router.dart';

@Controller('account')
class AccountController {
  const AccountController();

  @RequireAuth()
  @Get('me')
  String me(@Data() String token) => 'authenticated as $token';
}
```

</CodeFile>

| Request | Response |
| --- | --- |
| `GET /api/account/me` without `Authorization` | `401 Missing or invalid Authorization header` |
| `GET /api/account/me` with `Authorization: Bearer wrong` | `401 Invalid token` |
| `GET /api/account/me` with `Authorization: Bearer secret-token` | `200 {"data": "authenticated as secret-token"}` |

## Applying It to More Routes

Put `@RequireAuth()` on the controller, or on the app class, to protect every route under it. See [Scoping][scoping]. For role checks, add a second guard that reads what the first guard stored in `Data`. See the [Guards reference][guards-ref].

## Try It

```bash
dart run revali dev
curl -H 'Authorization: Bearer secret-token' http://localhost:8080/api/account/me
```

Next: [Error Handling](/revali/tutorials/error-handling) · [Middleware reference][middleware-ref] · [Testing](/revali/testing)

[lifecycle-component]: /constructs/revali_server/lifecycle-components
[middleware-ref]: /constructs/revali_server/lifecycle-components/advanced/middleware
[guards-ref]: /constructs/revali_server/lifecycle-components/advanced/guards
[data-sharing]: /constructs/revali_server/context/data-sharing
[scoping]: /constructs/revali_server/lifecycle-components#scoping
[configure-dependencies]: /revali/app-configuration/configure-dependencies
