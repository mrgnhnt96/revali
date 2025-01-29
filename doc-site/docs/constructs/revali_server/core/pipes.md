---
description: Transform values from one type to another
sidebar_position: 4
---

# Pipes

A `Pipe` is a used to transform a [binding] from the original type to another type to be delivered to the endpoint.

## Create a Pipe

To create a `Pipe`, you need to implement the `Pipe` class and implement the `transform` method.

```dart title="lib/pipes/my_pipe.dart"
import 'package:revali_router/revali_router.dart';

class UserPipe implements Pipe<String, User> {
    const UserPipe();

    @override
    Future<User> transform(String value, context) async {
        // Transform the value
    }
}
```

:::tip
Try using the [`create` cli][create-cli] to generate the pipe for you!

```bash
dart run revali_server create pipe
```

:::

The first type argument of the `Pipe` class is the type received from the binding. The second type argument is the type to be returned.

:::tip
`fromJson` is automatically detected, so a `Pipe` may not be needed! [Read more][json-binding].
:::

:::warning
You will get a runtime error if the received type is not the same as the type provided by the binding. You will also get a runtime error if the delivered type is not the same as the type expected by the parameter.

```dart
@Param('userId', UserPipe) String userId, // throws because `String` is not `User`
```

:::

## Usage

Pipes are tightly coupled with [bindings][binding-pipe-transform]. To use a `Pipe`, you need to provide your `Pipe` class in the binding.

```dart title="routes/controllers/my_controllers.dart"
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
    @Get(':userId')
    Future<User> getUser(
        // highlight-next-line
        @Param('userId', UserPipe) User user,
    ) async {
        // Get the user
    }
}
```

:::tip
If you want to use without the first argument, you can use the `.pipe` constructor.

```dart
@Param.pipe(UserPipe) User user,
```

:::

## Pipe Context

:::tip
Learn more about the Pipe Context [here][pipe-context].
:::

[binding]: ./binding.md
[json-binding]: ./binding.md#auto-fromjson
[pipe-context]: ../context/pipe.md
[binding-pipe-transform]: ./binding.md#pipe-transform
[create-cli]: ../getting-started/cli.md#create
