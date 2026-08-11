---
title: Middleware
description: Add request/response processing with Middleware
---

This tutorial walks through building two middleware components with the [`LifecycleComponent`][lifecycle-component] API: one that logs every request, and one that guards an endpoint behind an API key.

<Callout type="tip">

Middleware runs before guards, in the order it's registered. Read the full [Middleware reference][middleware-ref] for the complete list of possible results.

</Callout>

## Log every request

A `LifecycleComponent` method that returns `MiddlewareResult` acts as middleware. Bind `Request` to inspect the incoming request:

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

Apply it to an endpoint, controller, or the whole app by using it as an annotation:

<CodeFile name="routes/controllers/some_controller.dart">

```dart
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

Every request to `GET /some/logged` prints a line like `[GET] /some/logged` to the server's console before the endpoint runs.

## Guard an endpoint with an API key

Middleware can also stop a request before it reaches the endpoint, and share data with it via [`Data`][data-sharing]:

<CodeFile name="lib/components/require_api_key.dart">

```dart
import 'package:revali_router/revali_router.dart';

class RequireApiKey implements LifecycleComponent {
  const RequireApiKey();

  MiddlewareResult checkApiKey(
    @Header('X-Api-Key') String? apiKey,
    Data data,
  ) {
    if (apiKey == null) {
      return const MiddlewareResult.stop(
        statusCode: 401,
        body: 'Missing X-Api-Key header',
      );
    }

    data.add(apiKey);
    return const MiddlewareResult.next();
  }
}
```

</CodeFile>

The endpoint reads the value middleware stored in `Data` using the `@Data()` annotation:

<CodeFile name="routes/controllers/some_controller.dart">

```dart
@RequireApiKey()
@Get('protected-by-middleware')
String protectedByMiddleware(@Data() String apiKey) => 'key: $apiKey';
```

</CodeFile>

- A request without `X-Api-Key` gets `401 Missing X-Api-Key header` and never reaches `protectedByMiddleware`.
- A request with `X-Api-Key: my-key-123` reaches the endpoint, which echoes back `key: my-key-123`.

<Callout type="note">

This example checks for the mere presence of a key. For real authentication (verifying a token against a user), see the [Authentication tutorial][auth-tutorial] which uses a `Guard` instead — guards run after middleware and are the dedicated place for pass/block authorization decisions.

</Callout>

## What's next?

- [Error Handling](/revali/tutorials/error-handling) — turn exceptions into consistent error responses
- [Authentication](/revali/tutorials/authentication) — protect endpoints with a `Guard`
- [Lifecycle Components reference][lifecycle-component] — the full binding and registration model

[lifecycle-component]: /constructs/revali_server/lifecycle-components
[middleware-ref]: /constructs/revali_server/lifecycle-components/advanced/middleware
[data-sharing]: /constructs/revali_server/context/data-sharing
[auth-tutorial]: /revali/tutorials/authentication
