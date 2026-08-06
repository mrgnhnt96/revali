---
sidebar_position: 2
description: Create custom error responses with ExceptionCatcher
---

# Error Handling

This tutorial builds a domain exception and an `ExceptionCatcher` that turns it into a consistent JSON error response.

:::tip
`MissingArgumentException` (thrown when a `@Query`/`@Body`/… binding is missing or invalid) is already mapped to HTTP 400 automatically — you only need a custom catcher for your own exceptions. See the full [Exception Catchers reference][catchers-ref] for repetitive catchers and the default catch-all.
:::

## Define a domain exception

Exceptions are plain Dart classes -- nothing framework-specific:

```dart title="lib/exceptions/not_found_exception.dart"
class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;
}
```

## Catch it and shape the response

A `LifecycleComponent` method that returns `ExceptionCatcherResult<T>` catches every exception of type `T` thrown anywhere in the request lifecycle:

```dart title="lib/components/not_found_catcher.dart"
import 'package:revali_router/revali_router.dart';

class NotFoundCatcher implements LifecycleComponent {
  const NotFoundCatcher();

  ExceptionCatcherResult<NotFoundException> catchNotFound(
    NotFoundException exception,
  ) {
    return ExceptionCatcherResult.handled(
      statusCode: 404,
      body: {'error': exception.message},
    );
  }
}
```

The exception instance itself is bound automatically by matching the method's exception-typed parameter -- no annotation needed.

## Throw it and register the catcher

```dart title="routes/controllers/widget_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('widgets')
class WidgetController {
  const WidgetController();

  @NotFoundCatcher()
  @Get('missing')
  String missing() {
    throw const NotFoundException('Widget not found');
  }
}
```

`GET /widgets/missing` now returns `404` with body `{"error": "Widget not found"}`, instead of an unhandled-exception `500`.

:::note
In [debug mode][debug-mode] (the default for `revali dev`), the response body also includes a `__DEBUG__` field with the exception and stack trace. This is stripped in [profile and release modes][run-modes].
:::

Register `@NotFoundCatcher()` once at the app or controller level (instead of per-endpoint) to cover every route underneath it -- see [Scoping][scoping].

## What's next?

- [Authentication](./authentication.md) — block unauthorized requests with a `Guard`
- [Exception Catchers reference][catchers-ref] — default catch-all, repetitive catchers, and non-JSON bodies
- [Error Responses][error-responses] — the full `statusCode`/`headers`/`body` shape shared by Guards, Middleware, and Exception Catchers

[catchers-ref]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[debug-mode]: /revali/cli/dev#debug-mode-default
[run-modes]: /revali/cli/dev#run-modes
[scoping]: /constructs/revali_server/lifecycle-components/overview#scoping
[error-responses]: /constructs/revali_server/lifecycle-components/overview#error-responses
