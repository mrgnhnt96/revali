---
sidebar_position: 6
---

# Exception Catchers

An `ExceptionCatcher` is a Lifecycle Component that allows you to catch exceptions that are thrown during the request lifecycle. No matter where the exception is thrown, the request flow is aborted and the exception is caught by the server. The `ExceptionCatcher`'s responsibility is to handle certain types of exceptions and prepare an error response to be sent back to the client.

## Create an ExceptionCatcher

To create an `ExceptionCatcher`, you need to extend the `ExceptionCatcher` class and implement the `catchException` method. The `catchException` will only be called if the exception thrown is an instance of the type specified in the type argument of the `ExceptionCatcher` class.

In this example, only exceptions of type `MyException` will be caught by the `MyExceptionCatcher` class.

```dart title="lib/catchers/my_catcher.dart"
import 'package:revali_router/revali_router.dart';

final class MyExceptionCatcher extends ExceptionCatcher<MyException> {
    const MyExceptionCatcher();

    @override
    ExceptionCatcherResult catchException(exception, context, action) {
        return action.handled();
    }
}
```

::::important
A type parameter must be specified when extending the `ExceptionCatcher` class. This type parameter specifies the type of exception that the `ExceptionCatcher` will catch. Without this type parameter, the `ExceptionCatcher` will not be able to catch any exceptions.

:::caution
The type parameter must be a subtype of `Exception` and not `Exception` itself.
:::
::::

## Register an ExceptionCatcher

To register an `ExceptionCatcher`, annotate your `MyExceptionCatcher` class on the app, controller, or endpoint level.

```dart title="routes/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@MyExceptionCatcher()
class MyApp ...
```

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `MyExceptionCatcher` as a type reference using the `@Catchers()` annotation.

```dart title="routes/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@Catches([MyExceptionCatcher])
class MyApp ...
```

:::tip
Learn more about [type referencing][type-referencing].
:::

### Repetitive Catchers

Its not common, but you can create multiple `ExceptionCatcher` classes that catch the same type of exception. This can be useful if you want to handle the same type of exception in different ways.

```dart title="lib/catchers/my_other_catcher.dart"
import 'package:revali_router/revali_router.dart';

final class MyOtherCatcher extends ExceptionCatcher<MyException> {
    const MyOtherCatcher();

    @override
    ExceptionCatcherResult catchException(exception, context, action) {
        if (condition) {
            return action.handled();
        } else {
            return action.unhandled();
        }
    }
}
```

When `action.unhandled()` is returned, the next `ExceptionCatcher` that catches the same type of exception will be called.

## Handling the Response

The `ExceptionCatcher` is responsible for preparing the error response to be sent back to the client.

```dart title="lib/catchers/my_catcher.dart"
import 'package:revali_router/revali_router.dart';

final class MyExceptionCatcher extends ExceptionCatcher<MyException> {
    const MyExceptionCatcher();

    @override
    ExceptionCatcherResult catchException(exception, context, action) {
        return action.handled(
            statusCode: 500,
            headers: {
                HttpHeaders.contentTypeHeader: 'text/plain',
            }
            body: 'An error occurred',
        );
    }
}
```

Here's an example of how you can handle the response:

```dart
action.handled();
```

```dart
action.notHandled(
    statusCode: 500,
    headers: {},
    body: 'Internal Server Error',
);
```

::::tip
Learn about [returning error responses][error-responses].
:::important
If the `statusCode` is not set, the default status code will be 500.
:::
::::

## Default Exception Catcher

If you would like to catch all exceptions that weren't caught by any other `ExceptionCatcher`, you can extend the `DefaultExceptionCatcher` class and implement the `catchException` method. While you may be tempted to handle all exceptions in the default exception catcher, it is highly recommended to only handle exceptions that are not caught by any other `ExceptionCatcher`.

```dart title="lib/catchers/unhandled_catcher.dart"
import 'package:revali_router/revali_router.dart';

class UnhandledCatcher extends DefaultExceptionCatcher {
    const UnhandledCatcher();

    @override
    ExceptionCatcherResult catchException(exception, context, action) {
        return action.handled();
    }
}
```

:::note
There isn't a limit to the number of `DefaultExceptionCatchers` that can be created.
:::

:::tip
Scope the `DefaultExceptionCatcher` to the app level to catch all unhandled exceptions.
:::

## Unhandled Exceptions

When an exception is not handled by any `ExceptionCatcher`, the default status code will be 500. The body will be set to the default error message.

```plaintext
Internal Server Error
```

:::tip
Learn how you can customize the internal server error message in the [docs][default-responses]
:::

Learn more about [type referencing][type-referencing].
:::

## Exception Catcher Context

:::tip
Learn more about the Exception Catcher Context [here][exception-catcher-context].
:::

[type-referencing]: ../tidbits.md#using-types-in-annotations
[error-responses]: ../lifecycle-components/overview.md#error-responses
[default-responses]: ../../../revali/app-configuration/default-responses.md
[exception-catcher-context]: ../context/exception-catcher.md
