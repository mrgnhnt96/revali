# Guards

A `Guard` is a lifecycle component that is used to protect the execution of the controller and endpoint.

A guard can be used for checking if the user is authenticated, if the user has the correct permissions, or any other condition that needs to be met before the controller or endpoint is executed.

## Execution

Guards are executed after the middleware, before the interceptors.

## Create a Guard

To create a `Guard`, you need to implement the `Guard` class and implement the `canActivate` method.

```dart title="lib/guards/my_guard.dart"
import 'package:revali_router/revali_router.dart';

class MyGuard extends Guard {
    const MyGuard();

    @override
    GuardResult canActivate(context, action) {
        return action.yes();
    }
}
```

:::note
There's no limit to the number of guards that can be applied to a controller or endpoint. Guards are executed in the order they are registered.
:::

### Possible Results

The `GuardResult` has two possible results: `yes` and `no`. The `yes` result allows the request to continue to the controller or endpoint. The `no` result stops the request from continuing any further in the request flow.

An alternative to using the `action.no` method is to throw an exception. Create an [exception catcher](./exception-catchers) to catch the exception and handle the error response.

::::tip
Learn about returning error responses in the [docs](/constructs/revali_server/lifecycle-components#error-responses).

:::important
If the `statusCode` is not set, the default status code will be 403.
:::
::::

## Register the Guard

To register the `Guard`, annotate your `Guard` class on the app, controller, or endpoint level.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyGuard()
@Controller('')
class MyController ...
```

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `Guard` as a type reference using the `@Guards()` annotation.

```dart title="routes/controllers/my_controller.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Guards([MyGuard])
@Controller('')
class MyController ...
```

:::tip
Learn more about [type referencing](/constructs/revali_server/tidbits#using-types-in-annotations).
:::
