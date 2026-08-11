---
title: Authentication
description: Secure your endpoints with a Guard
---

This tutorial protects an endpoint behind a bearer token using a `Guard` -- the lifecycle component dedicated to pass/block authorization decisions. It runs after middleware and before interceptors, so by the time your endpoint executes, authorization is already settled.

## Build the guard

A `LifecycleComponent` method that returns `GuardResult` acts as a guard. Read the `Authorization` header, validate it, and share the resolved value with the endpoint via [`Data`][data-sharing]:

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

    data.add(token);
    return const GuardResult.pass();
  }
}

// Replace with a real lookup against your auth provider / database.
bool isValidToken(String token) => token == 'secret-token';
```

</CodeFile>

<Callout type="tip">

This example checks a hardcoded token for simplicity. In a real app, `isValidToken` (or the whole guard) would call an injected auth service -- see [Configure Dependencies][configure-dependencies] for registering one via DI, and pass it to the guard through its constructor.

</Callout>

## Protect an endpoint

Apply the guard like any other lifecycle component, and read the token it stored in `Data` with the `@Data()` annotation:

<CodeFile name="routes/controllers/account_controller.dart">

```dart
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

- `GET /account/me` with no `Authorization` header, or a malformed one → `401 Missing or invalid Authorization header`.
- `GET /account/me` with `Authorization: Bearer wrong` → `401 Invalid token`.
- `GET /account/me` with `Authorization: Bearer secret-token` → `200 authenticated as secret-token`.

## Protecting more than one endpoint

Apply `@RequireAuth()` at the controller or app level (instead of on each endpoint) to guard every route beneath it in one place -- see [Scoping][scoping]. For role-based checks on top of authentication, add a second guard that reads the user `Data` the first guard stored and blocks based on role, the same pattern shown in the [Guards reference][guards-ref]'s `RoleGuard` example.

## What's next?

- [Error Handling](/revali/tutorials/error-handling) — return consistent error responses for your own exceptions
- [Guards reference][guards-ref] — the full `GuardResult` API and a role-based example
- [Data Sharing][data-sharing] — passing values between lifecycle components and endpoints

[data-sharing]: /constructs/revali_server/context/data-sharing
[configure-dependencies]: /revali/app-configuration/configure-dependencies
[scoping]: /constructs/revali_server/lifecycle-components#scoping
[guards-ref]: /constructs/revali_server/lifecycle-components/advanced/guards
