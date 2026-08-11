---
title: Error Handling
description: Create custom error responses with ExceptionCatcher
---

This tutorial builds a domain exception and an `ExceptionCatcher` that turns it into a consistent JSON error response.

<Callout type="tip">

`MissingArgumentException` (thrown when a `@Query`/`@Body`/… binding is missing or invalid) is already mapped to HTTP 400 automatically — you only need a custom catcher for your own exceptions. See the full [Exception Catchers reference][catchers-ref] for repetitive catchers and the default catch-all.

</Callout>

## Define a domain exception

Exceptions are plain Dart classes -- nothing framework-specific:

<CodeFile name="lib/exceptions/not_found_exception.dart">

```dart
class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;
}
```

</CodeFile>

## Catch it and shape the response

A `LifecycleComponent` method that returns `ExceptionCatcherResult<T>` catches every exception of type `T` thrown anywhere in the request lifecycle:

<CodeFile name="lib/components/not_found_catcher.dart">

```dart
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

</CodeFile>

The exception instance itself is bound automatically by matching the method's exception-typed parameter -- no annotation needed.

## Throw it and register the catcher

<CodeFile name="routes/controllers/widget_controller.dart">

```dart
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

</CodeFile>

`GET /widgets/missing` now returns `404` with body `{"error": "Widget not found"}`, instead of an unhandled-exception `500`.

<Callout type="note">

In [debug mode][debug-mode] (the default for `revali dev`), the response body also includes a `__DEBUG__` field with the exception and stack trace. This is stripped in [profile and release modes][run-modes].

</Callout>

Register `@NotFoundCatcher()` once at the app or controller level (instead of per-endpoint) to cover every route underneath it -- see [Scoping][scoping].

## What's next?

- [Authentication](/revali/tutorials/authentication) — block unauthorized requests with a `Guard`
- [Exception Catchers reference][catchers-ref] — default catch-all, repetitive catchers, and non-JSON bodies
- [Error Responses][error-responses] — the full `statusCode`/`headers`/`body` shape shared by Guards, Middleware, and Exception Catchers

[catchers-ref]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[debug-mode]: /revali/cli/dev#debug-mode-default
[run-modes]: /revali/cli/dev#run-modes
[scoping]: /constructs/revali_server/lifecycle-components#scoping
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
