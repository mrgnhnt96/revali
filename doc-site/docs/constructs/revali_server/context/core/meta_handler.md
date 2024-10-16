# Meta Handler

The `MetaHandler` object is used to store meta data in the context. Meta data is used to store additional information about the endpoint. The meta data is stored and retrieved by type.

:::tip
Learn how to create meta data using the [`Meta`](./meta) object
:::

## Properties

### `add`

When adding new meta data to the context, the `add` method is used. When the data is added, it doesn't replace any existing data, but rather appends to it.

```dart
context.meta.add<T>(T value);
```

:::note
There are some Lifecycle Components that can only read data from the `MetaHandler` and not write to it.
:::

:::tip
Its not recommended to store primitive types in the `MetaHandler`. Instead, create a class that holds the primitive type or use [extension types](https://dart.dev/language/extension-types).

```dart
extension type Role(String _) implements String {}

context.meta.add(Role('admin'));
context.meta.get<Role>();
```

:::

### `get`

returns all the meta data of a specific type.

```dart
List<T> values = context.meta.get<T>();
```

### `has`

checks if the context has meta data of a specific type.

```dart
bool has = context.meta.has<T>();
```

## Example

An example of the `MetaHandler` is when you have a controller that requires an `Authorization` header to be present in the request, but you want to allow unauthenticated requests to a specific route. You can create a `Public` meta class that you can register to the endpoint.

```dart title="lib/meta/public.dart"
import 'package:revali_router/revali_router.dart';

class Public extends Meta {
    const Public();
}
```

Now that we have the `Public` meta class, we can register it to the endpoint.

```dart title="routes/controllers/user_controller.dart"
import 'package:revali_router/revali_router.dart';

@AuthGuard()
@Controller('users')
class UserController extends Controller {
    const UserController();

    // highlight-next-line
    @Public()
    @Get()
    Future<List<User>> getUsers() async {
        return [];
    }
}
```

Within the `AuthGuard` guard, we can check if the `Public` meta is present in the context and allow the request to continue.

```dart title="lib/guards/auth_guard.dart"
import 'package:revali_router/revali_router.dart';

class AuthGuard implements Guard {
    const AuthGuard();

    @override
    Future<GuardResult> canActivate(context, action) async {
        // highlight-start
        if (context.meta.has<Public>()) {
            return action.yes();
        }
        // highlight-end

        if (!context.request.headers.containsKey('Authorization')) {
            return action.no(
                status: 401,
                message: 'Unauthorized',
            );
        }

        return action.yes();
    }
}
```
