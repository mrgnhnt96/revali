---
title: Error Handling
description: Create custom error responses with ExceptionCatcher
---

In this tutorial you turn one of your own exceptions into a consistent JSON error response with an exception catcher. If you only need a status and an error code, throwing [`HttpError`](/revali/app-configuration/default-responses#httperror) is simpler and needs no catcher.

You don't need a catcher for missing or invalid bindings: Revali already turns `MissingArgumentException` into a 400.

## Define a domain exception

An exception is a plain Dart class:

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
import 'package:my_app/exceptions/not_found_exception.dart';
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

The parameter typed as the exception receives the thrown exception automatically, with no annotation needed.

## Throw it and register the catcher

<CodeFile name="routes/controllers/widget_controller.dart">

```dart
import 'package:my_app/components/not_found_catcher.dart';
import 'package:my_app/exceptions/not_found_exception.dart';
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

`GET /api/widgets/missing` now returns `404` with the body `{"error": "Widget not found"}` instead of a `500`. A catcher's body is sent as written: it isn't wrapped in `data`.

<Callout type="note">

In [debug mode][debug-mode] (the default for `revali dev`), the response body also includes a `__DEBUG__` field with the exception and stack trace. This is stripped in [profile and release modes][run-modes].

</Callout>

Register `@NotFoundCatcher()` once at the app or controller level (instead of on each endpoint) to cover every route under it. See [Scoping][scoping].

Next: [Middleware and Guards](/revali/tutorials/middleware) · [Exception Catchers reference][catchers-ref] · [Error Responses](/revali/app-configuration/default-responses)

[catchers-ref]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[debug-mode]: /revali/cli/dev#debug-mode-default
[run-modes]: /revali/cli/dev#run-modes
[scoping]: /constructs/revali_server/lifecycle-components#scoping
