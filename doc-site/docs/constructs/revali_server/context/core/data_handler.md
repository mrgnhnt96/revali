---
description: Read and write data to share across components
---

# Data Handler

The `DataHandler` is a singleton object to share data between different parts of your application. It is a mutable property of the context object. The data within the `DataHandler` is stored and retrieved by type.

## Adding Data

To add data to the `DataHandler`, you can use the `add` method. Every time you add data, if there was already data of the same type, it will be replaced.

```dart
context.data.add<T>(T value);
```

:::note
There are some Lifecycle Components that can only read data from the `DataHandler` and not write to it.
:::

:::tip
Its not recommended to store primitive types in the `DataHandler`. Instead, create a class that holds the primitive type or use [extension types][extension-types].

```dart
extension type UserId(String value) implements String {}

context.data.add(UserId('1234'));
context.data.get<UserId>();
```

:::

## Removing Data

To remove data from the `DataHandler`, you can use the `remove` method.

```dart
final success = context.data.remove<T>();

print(success); // true if data was removed, false if not
```

:::note
If there is no data of the type you are trying to remove, nothing will happen.
:::

:::note
There are some Lifecycle Components that can only read data from the `DataHandler` and not write to it.
:::

## Checking for Data

To check if data of a certain type exists in the `DataHandler`, you can use the `has` method. Or you can use the `contains` method for checking if the value exists.

```dart
final hasData = context.data.has<T>();

print(hasData); // true if data exists, false if not
```

```dart
final hasValue = context.data.contains<T>(T value);

print(hasValue); // true if value exists, false if not
```

:::note
Since the `DataHandler` can only store one value per type, the `contains` method will only return `true` if the value is the same as the one stored.
:::

## Reading Data

To read data from the `DataHandler`, you can use the `get` method.

```dart
T? value = context.data.get<T>();
```

## Example

An example of the `DataHandler` is when you need to retrieve a `User` based on a value received from the request. You will more than likely need to access the `User` object in different Lifecycle Components. So, you can store the `User` object in the `DataHandler` and retrieve it when needed.

```dart title="lib/components/middleware/user_middleware.dart"
import 'package:revali_router/revali_router.dart';

class UserMiddleware implements Middleware {
    const UserMiddleware({
        required this.service,
    });

    final UserService service;

    @override
    Future<MiddlewareResult> use(MiddlewareContext context) async {
        final userId = context.request.pathParameters['userId'];

        final user = await service.getUser(userId);

        context.data.add(user);

        return const MiddlewareResult.next()
    }
}
```

Now that we have the user stored in the `DataHandler` we can retrieve it in a different Lifecycle Component. Let's say that we have a `RoleGuard` that checks if the user has the correct role to access a resource.

```dart title="lib/components/middleware/role_middleware.dart"
import 'package:revali_router/revali_router.dart';

class RoleGuard implements Guard {
    const RoleGuard({
        required this.role,
    });

    final String role;

    @override
    Future<GuardResult> protect(GuardContext context) async {
        final user = context.data.get<User>();

        // Return 500 if the user is not found
        if (user == null) {
            return const GuardResult.block(
                statusCode: 500,
            );
        }

        if (user.role != role) {
            return const GuardResult.block(
                statusCode: 403,
                message: 'User does not have the correct role to access this resource.',
            );
        }

        return const GuardResult.pass();
    }
}
```

:::note
While in this example we are returning a `500` status code, you could retrieve the user from the database in the `RoleGuard` if you wanted to.
:::

[extension-types]: https://dart.dev/language/extension-types
