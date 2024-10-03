# Exception Catchers

An `ExceptionCatcher` is a lifecycle component that allows you to catch exceptions that are thrown during the request lifecycle. No matter where the exception is thrown, the request flow is aborted and the exception is caught by the server. The `ExceptionCatcher`'s responsibility is to handle certain types of exceptions and prepare an error response to be sent back to the client.

## Create an ExceptionCatcher

To create an `ExceptionCatcher`, you need to extend the `ExceptionCatcher` class and implement the `catchException` method. The `catchException` will only be called if the exception thrown is an instance of the type specified in the type argument of the `ExceptionCatcher` class.

In this example, only exceptions of type `MyException` will be caught by the `MyCatcher` class.

```dart title="lib/catchers/my_catcher.dart"
import 'package:revali_router/revali_router.dart';

class MyCatcher extends ExceptionCatcher<MyException> {
    const MyCatcher();

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

To register an `ExceptionCatcher`, annotate your `ExceptionCatcher` class on the app, controller, or endpoint level.

```dart title="routes/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@MyExceptionCatcher()
class MyApp ...
```

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `ExceptionCatcher` as a type reference.

```dart title="routes/my_app.dart"
import 'package:revali_router/revali_router.dart';

@App()
// highlight-next-line
@Catches(MyException)
class MyApp ...
```

:::tip
Learn more about [type referencing](/constructs/revali_server/tidbits#using-types-in-annotations).
:::

### Repetitive Catchers

Its not common, but you can create multiple `ExceptionCatcher` classes that catch the same type of exception. This can be useful if you want to handle the same type of exception in different ways.

```dart title="lib/catchers/my_other_catcher.dart"
import 'package:revali_router/revali_router.dart';

class MyOtherCatcher extends ExceptionCatcher<MyException> {
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

### Catching Unhandled Exceptions

If you would like to catch all exceptions that weren't caught by any other `ExceptionCatcher`, you can extend the `DefaultExceptionCatcher` class and implement the `catchException` method.

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

## Handling the Response

The `ExceptionCatcher` is responsible for preparing the error response to be sent back to the client.

The `action.handled` method can accept the `statusCode`, `headers`, and `body`. The status code and body values passed to the `action.handled` method will override any values previous set by the request flow, while the headers will be merged with the headers set by the request flow.

:::important
If the `statusCode` is not set, the default status code will be 500.
:::

```dart title="lib/catchers/my_catcher.dart"
import 'package:revali_router/revali_router.dart';

class MyCatcher extends ExceptionCatcher<MyException> {
    const MyCatcher();

    @override
    ExceptionCatcherResult catchException(exception, context, action) {
        return action.handled(
            statusCode: 400,
            headers: {
                HttpHeaders.contentTypeHeader: 'text/plain',
            }
            body: 'An error occurred',
        );
    }
}
```

## Debug Mode

When an exception is thrown during [debug mode](/revali/cli/dev#run-modes), a stack trace will be included in the error response.

Depending on the response content type, the stack trace will be formatted differently.

### String Debug Message

```dart
action.handled(
    body: 'An error occurred',
);
```

```plaintext
An error occurred

__DEBUG__:
Error: Instance of 'MyException'

Stack Trace:
routes/hello_controller.dart 13:5                            HelloController.hello
.revali/server/routes/__hello.dart 15:16                     hello.<fn>
package:revali_router/src/router/execute.dart 56:22          Execute.run.<fn>
dart:async                                                   runZonedGuarded
package:revali_router/src/router/execute.dart 54:11          Execute.run
package:revali_router/src/router/router.dart 159:22          Router.handle
package:revali_router/src/server/handle_requests.dart 23:20  handleRequests
```

### Map Debug Message

```dart
action.handled(
    body: {
        'message': 'An error occurred',
    },
);
```

```json
{
  "message": "An error occurred",
  "__DEBUG__": {
    "error": "Instance of 'MyException'",
    "stackTrace": [
      "routes/hello_controller.dart 13:5                            HelloController.hello",
      ".revali/server/routes/__hello.dart 15:16                     hello.<fn>",
      "package:revali_router/src/router/execute.dart 56:22          Execute.run.<fn>",
      "dart:async                                                   runZonedGuarded",
      "package:revali_router/src/router/execute.dart 54:11          Execute.run",
      "package:revali_router/src/router/router.dart 159:22          Router.handle",
      "package:revali_router/src/server/handle_requests.dart 23:20  handleRequests"
    ]
  }
}
```

### List Debug Message

```dart
action.handled(
    body: [
        'An error occurred',
    ],
);
```

```json
[
  "An error occurred",
  {
    "__DEBUG__": {
      "error": "Instance of 'MyException'",
      "stackTrace": [
        "routes/hello_controller.dart 13:5                            HelloController.hello",
        ".revali/server/routes/__hello.dart 15:16                     hello.<fn>",
        "package:revali_router/src/router/execute.dart 56:22          Execute.run.<fn>",
        "dart:async                                                   runZonedGuarded",
        "package:revali_router/src/router/execute.dart 54:11          Execute.run",
        "package:revali_router/src/router/router.dart 159:22          Router.handle",
        "package:revali_router/src/server/handle_requests.dart 23:20  handleRequests"
      ]
    }
  }
]
```

## Release Mode

Release mode is very similar to debug mode, with a few exceptions (pun intended).

:::tip
Learn more about [run modes](/revali/cli/dev#run-modes).
:::

### Debug Message

The error response will not include any debug messages.

### 500 Status Code

When an exception is not handled by any `ExceptionCatcher`, the default status code will be 500. The body will be set to the default error message.

```plaintext
Internal Server Error
```

:::tip
Learn how you can customize the internal server error message in the [docs](/revali/app-configuration/default-responses)
:::
