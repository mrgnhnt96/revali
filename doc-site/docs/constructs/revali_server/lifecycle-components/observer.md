---
sidebar_position: 1
---

# Observer

The `Observer` component is a Lifecycle Component that can be used to observe the request and response before or after the request is processed. Regardless of the request flow's result, the observer is executed. Meaning that even if the request is rejected by a guard or an exception is thrown, the observer will still be executed.

Observers are unique in that they can only be registered at the app level. This means that all requests will be observed by the observer.

Observers are useful for logging, monitoring, and other tasks that need to be executed before or after the request.

:::important
Observers are not intended to modify the request or response. If you need to modify the request or response, use an [interceptor][interceptors].
:::

## Execution

Observers are executed immediately after the request is received and before the response is returned to the client.

## Create an Observer

To create an `Observer`, you need to implement the `Observer` class and implement the `see` method.

```dart title="lib/observers/my_observer.dart"
import 'package:revali_router/revali_router.dart';

class MyObserver extends Observer {
    const MyObserver();

    @override
    Future<void> see(request, response) async {}
}
```

:::note
There's no limit to the number of observers that can be applied to an app. Observers are executed in the order they are registered.
:::

## Register the Observer

To register the `Observer`, annotate your `Observer` class on the app level.

```dart title="routes/my_app.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyObserver()
@App()
class MyApp ...
```

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `Observer` as a type reference using the `@Observers()` annotation.

```dart title="routes/my_app.dart"
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Observers([MyObserver])
@App()
class MyApp ...
```

[interceptors]: ./interceptors.md
