# Catchers

An `ExceptionCatcher` is a lifecycle component that allows you to catch exceptions that are thrown during the request lifecycle. No matter where the exception is thrown, the request flow is aborted and the exception is caught by the server. The `ExceptionCatcher`'s responsibility is to handle certain types of exceptions and prepare an error response to be sent back to the client.

## Create an ExceptionCatcher

To create an `ExceptionCatcher`, you need to extend the `ExceptionCatcher` class and implement the `catchException` method. The `catchException` will only be called if the exception thrown is an instance of the type specified in the type argument of the `ExceptionCatcher` class.

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

## Scoping

`ExceptionCatcher` can be applied at the app, controller, or request level. By applying the `ExceptionCatcher` at different levels, you can control where the exception is or isn't caught.

### The App

To catch all exceptions thrown regardless of where they are thrown, you can annotate the app with the `ExceptionCatcher`.

```dart title="routes/apps/my_app.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyExceptionCatcher()
@App()
class MyApp ...
```

:::info
Whether the request was sent to "Controller A" or "Controller B", the `MyExceptionCatcher` will catch the exception.
:::

### The Controller

To catch all exceptions thrown in a specific controller, you can annotate the controller with the `ExceptionCatcher`.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyExceptionCatcher()
@Controller('')
class MyController ...
```

:::info
The `MyExceptionCatcher` will only catch exceptions thrown in the `MyController` controller. If an exception is thrown in another controller, the `MyExceptionCatcher` will not catch it.
:::

### The Request

To catch all exceptions thrown in a specific request, you can annotate the request with the `ExceptionCatcher`.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('')
class MyController {
    const MyController();

    @Get()
    // highlight-next-line
    @MyExceptionCatcher()
    String hello() ...

    @Post()
    void goodbye() ...
}
```

:::info
The `MyExceptionCatcher` will only catch exceptions thrown in the `hello` endpoint. If an exception is thrown in the `goodbye` endpoint, the `MyExceptionCatcher` will not catch it
:::
