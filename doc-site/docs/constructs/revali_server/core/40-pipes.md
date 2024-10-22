# Pipes

A `Pipe` is a used to transform a [binding](./binding) from the original type to another type to be delivered to the endpoint.

## Create a Pipe

To create a `Pipe`, you need to implement the `Pipe` class and implement the `transform` method.

```dart title="lib/pipes/my_pipe.dart"
import 'package:revali_router/revali_router.dart';

class UserPipe extends Pipe<String, User> {
    const UserPipe();

    @override
    Future<User> transform(String value, context) async {
        // Transform the value
    }
}
```

## Usage

Pipes are tightly coupled with [bindings](./binding#pipe-transform). To use a `Pipe`, you need to provide your `Pipe` class in the binding.

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

## Pipe Context

:::tip
Learn more about the Pipe Context [here](../context/pipe)
:::
