---
title: Observer
description: Observe incoming requests and outgoing responses
---

The `Observer` component is a Lifecycle Component that can be used to observe the request and response before or after the request is processed. Regardless of the request flow's result, the observer is executed. Meaning that even if the request is rejected by a guard or an exception is thrown, the observer will still be executed.

Observers are unique in that they can only be registered at the app level. This means that all requests will be observed by the observer.

Observers are useful for logging, monitoring, and other tasks that need to be executed before or after the request.

<Callout type="important">

Observers are not intended to modify the request or response. If you need to modify the request or response, use an [interceptor][interceptors].

</Callout>

## Execution

Observers are executed immediately after the request is received and before the response is returned to the client.

## Create an Observer

To create an `Observer`, you need to implement the `Observer` class and implement the `see` method.

<CodeFile name="lib/components/observers/my_observer.dart">

```dart
import 'package:revali_router/revali_router.dart';

class MyObserver implements Observer {
    const MyObserver();

    @override
    Future<void> see(request, response) async {}
}
```

</CodeFile>

<Callout type="tip">

Try using the [`create` cli][create-cli] to generate the observer for you!

```bash
dart run revali create observer
```

</Callout>

<Callout type="note">

There's no limit to the number of observers that can be applied to an app. Observers are executed in the order they are registered.

</Callout>

## Register the Observer

To register the `Observer`, annotate your `Observer` class on the app level.

<CodeFile name="routes/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@MyObserver()
@App()
class MyApp ...
```

</CodeFile>

### Register as Type Reference

If you have a parameter that can not be provided at compile time, you can register the `Observer` as a type reference using the `@Observers()` annotation.

<CodeFile name="routes/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Observers([MyObserver])
@App()
class MyApp ...
```

</CodeFile>

[interceptors]: /constructs/revali_server/lifecycle-components/advanced/interceptors
[create-cli]: /constructs/revali_server/getting-started/cli#code-generation-made-easy
