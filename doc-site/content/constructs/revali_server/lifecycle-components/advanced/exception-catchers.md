---
title: Exception Catchers
---

An `ExceptionCatcher` is a Lifecycle Component that allows you to catch exceptions that are thrown during the request lifecycle. No matter where the exception is thrown, the request flow is aborted and the exception is caught by the server. The `ExceptionCatcher`'s responsibility is to handle certain types of exceptions and prepare an error response to be sent back to the client.

## Recipes

- Prefer a **domain exception → 4xx** catcher for expected client failures (`ValidationException`, `UnauthorizedException`, etc.).
- Do **not** use `ExceptionCatcher<Exception>` as a typed catcher — the runtime requires a concrete subtype (see below). Use `DefaultExceptionCatcher` only when you intentionally want a catch-all.
- Prefer the free `LifecycleComponent` form (method returning `ExceptionCatcherResult<MyError>`) for new code; classic `extends ExceptionCatcher<T>` remains supported.
- **`MissingArgumentException`** (missing/invalid `@Query`/`@Body`/… bindings) is mapped by the framework to **HTTP 400** automatically — you do not need a custom catcher unless you want a different body shape.

## Create an ExceptionCatcher

To create an `ExceptionCatcher`, you need to extend the `ExceptionCatcher` class and implement the `catchException` method. The `catchException` will only be called if the exception thrown is an instance of the type specified in the type argument of the `ExceptionCatcher` class.

In this example, only exceptions of type `MyException` will be caught by the `MyExceptionCatcher` class.

<CodeFile name="lib/components/catchers/my_catcher.dart">

```dart
import 'package:revali_router/revali_router.dart';

final class MyExceptionCatcher extends ExceptionCatcher<MyException> {
    const MyExceptionCatcher();

    @override
    ExceptionCatcherResult catchException(MyException exception, Context context) {
        return const ExceptionCatcherResult.handled();
    }
}
```

</CodeFile>

<Callout type="important">

A type parameter must be specified when extending the `ExceptionCatcher` class. This type parameter specifies the type of exception that the `ExceptionCatcher` will catch. Without this type parameter, the `ExceptionCatcher` will not be able to catch any exceptions.

<Callout type="caution">

The type parameter must be a subtype of `Exception` and not `Exception` itself.

</Callout>

</Callout>

## Register an ExceptionCatcher

To register an `ExceptionCatcher`, annotate your `MyExceptionCatcher` class on the app, controller, or endpoint level.

<CodeFile name="routes/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@MyExceptionCatcher()
class MyApp ...
```

</CodeFile>

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `MyExceptionCatcher` as a type reference using the `@Catchers()` annotation.

<CodeFile name="routes/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@Catches([MyExceptionCatcher])
class MyApp ...
```

</CodeFile>

<Callout type="tip">

Learn more about [type referencing][type-referencing].

</Callout>

### Repetitive Catchers

Its not common, but you can create multiple `ExceptionCatcher` classes that catch the same type of exception. This can be useful if you want to handle the same type of exception in different ways.

<CodeFile name="lib/components/catchers/my_other_catcher.dart">

```dart
import 'package:revali_router/revali_router.dart';

final class MyOtherCatcher extends ExceptionCatcher<MyException> {
    const MyOtherCatcher();

    @override
    ExceptionCatcherResult catchException(MyException exception, Context context) {
        if (condition) {
            return const ExceptionCatcherResult.handled();
        } else {
            return const ExceptionCatcherResult.unhandled();
        }
    }
}
```

</CodeFile>

When `ExceptionCatcherResult.unhandled()` is returned, the next `ExceptionCatcher` that catches the same type of exception will be called.

## Handling the Response

The `ExceptionCatcher` is responsible for preparing the error response to be sent back to the client.

<CodeFile name="lib/components/catchers/my_catcher.dart">

```dart
import 'package:revali_router/revali_router.dart';

final class MyExceptionCatcher extends ExceptionCatcher<MyException> {
    const MyExceptionCatcher();

    @override
    ExceptionCatcherResult catchException(MyException exception, Context context) {
        return const ExceptionCatcherResult.handled(
            statusCode: 500,
            headers: {
                HttpHeaders.contentTypeHeader: 'text/plain',
            }
            body: 'An error occurred',
        );
    }
}
```

</CodeFile>

Here's an example of how you can handle the response:

```dart
const ExceptionCatcherResult.handled();
```

```dart
const ExceptionCatcherResult.unhandled(
    statusCode: 500,
    headers: {},
    body: 'Internal Server Error',
);
```

<Callout type="tip">

Learn about [returning error responses][error-responses].
<Callout type="important">

If the `statusCode` is not set, the default status code will be 500.

</Callout>

</Callout>

## Default Exception Catcher

If you would like to catch all exceptions that weren't caught by any other `ExceptionCatcher`, you can extend the `DefaultExceptionCatcher` class and implement the `catchException` method. While you may be tempted to handle all exceptions in the default exception catcher, it is highly recommended to only handle exceptions that are not caught by any other `ExceptionCatcher`.

<CodeFile name="lib/components/catchers/unhandled_catcher.dart">

```dart
import 'package:revali_router/revali_router.dart';

class UnhandledCatcher extends DefaultExceptionCatcher {
    const UnhandledCatcher();

    @override
    ExceptionCatcherResult catchException(exception, context) {
        return const ExceptionCatcherResult.handled();
    }
}
```

</CodeFile>

<Callout type="note">

There isn't a limit to the number of `DefaultExceptionCatchers` that can be created.

</Callout>

<Callout type="tip">

Scope the `DefaultExceptionCatcher` to the app level to catch all unhandled exceptions.

</Callout>

## Unhandled Exceptions

When an exception is not handled by any `ExceptionCatcher`, the default status code will be 500. The body will be set to the default error message.

```plaintext
Internal Server Error
```

<Callout type="tip">

Learn how you can customize the internal server error message in the [docs][default-responses]

</Callout>

Learn more about [type referencing][type-referencing].

[type-referencing]: /constructs/revali_server/tidbits#using-types-in-annotations
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
[default-responses]: /revali/app-configuration/default-responses
