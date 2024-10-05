# Data Handler

The `DataHandler` is a singleton object to share data between different parts of your application. It is a mutable property of the context object. The data within the `DataHandler` is stored and retrieved by type.

## Adding Data

To add data to the `DataHandler`, you can use the `add` method.

```dart
context.data.add<T>(T value);
```

:::note
There are some lifecycle components that can only read data from the `DataHandler` and not write to it.
:::

## Reading Data

To read data from the `DataHandler`, you can use the `get` method.

```dart
T? value = context.data.get<T>();
```

## Example

An example of the `DataHandler` is when you need to retrieve a `User` based on a value received from the request. You will more than likely need to access the `User` object in different lifecycle components. So, you can store the `User` object in the `DataHandler` and retrieve it when needed.

```dart title="lib/middleware/user_middleware.dart"
import 'package:revali_router/revali_router.dart';

class UserMiddleware extends Middleware {
    const UserMiddleware({
        required this.service,
    });

    final UserService service;

    @override
    Future<MiddlewareResult> use(context, action) async {
        final userId = context.request.pathParameters['userId'];

        final user = await service.getUser(userId);

        context.data.add(user);

        return action.next()
    }
}
```

Now that we have the user stored in the `DataHandler` we can retrieve it in a different lifecycle component. Let's say that we have a `RoleGuard` that checks if the user has the correct role to access a resource.

```dart title="lib/middleware/role_middleware.dart"
import 'package:revali_router/revali_router.dart';

class RoleGuard extends Guard {
    const RoleGuard({
        required this.role,
    });

    final String role;

    @override
    GuardResult canActivate(context, action) {
        final user = context.data.get<User>();

        // Return 500 if the user is not found
        if (user == null) {
            return action.no(
                statusCode: 500,
            );
        }

        if (user.role != role) {
            return action.no(
                statusCode: 403,
                message: 'User does not have the correct role to access this resource.',
            );
        }

        return action.yes();
    }
}
```

:::note
While in this example we are returning a `500` status code, you could retrieve the user from the database in the `RoleGuard` if you wanted to.
:::
