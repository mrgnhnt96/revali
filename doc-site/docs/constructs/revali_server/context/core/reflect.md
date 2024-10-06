# Reflect Handler

The `ReflectHandler` is a helper class that provides a way to analyze meta data of a specific type.

## Properties

### `get`

Gets a `Reflector` instance for a specific type. The specific type is typically a class that you've defined.

```dart
Reflector reflector = context.reflect.get<T>();
```

### `byType`

An alternative way to retrieve the you can use the `byType` method.

## Reflector

The `Reflector` class provides a way to analyze [`Meta`](./meta_handler) data on properties of a specific type.

:::tip
Learn how to create meta data using the [`Meta`](../../metadata/meta) object
:::

### `get`

Getting a `Meta` instance for a specific property of a type.

```dart
ReadOnlyMetaHandler meta = context.reflect.get<T>().get('email');
```

```dart
Reflector reflector = context.reflect.byType(User);
```

### `meta`

Returns all the meta data of a specific type.

```dart
Map<String, ReadOnlyMeta> final meta = context.reflect.get<T>().meta;
```

## Example

An example of the `ReflectHandler` is when you have a return type that you want to make sure never returns a value to the client. You can create a `NoReturn` meta class that you can register to the endpoint's return type.

```dart title="lib/meta/no_return.dart"
import 'package:revali_router/revali_router.dart';

class NoReturn extends Meta {
    const NoReturn();
}
```

Now that we have the `NoReturn` meta class, we can register it to the field of the endpoint's return type.

```dart title="lib/models/user.dart"
class User {
    const User(this.email, this.password);

    final String email;

    // highlight-next-line
    @NoReturn()
    final String password;
}
```

Now that we have the `NoReturn` meta class registered to the `password` field, we can use the `ReflectHandler` to analyze the meta data of the `User` class.

```dart title="lib/interceptor/user_interceptor.dart"
import 'package:revali_router/revali_router.dart';


class UserInterceptor implements Interceptor {
    const UserInterceptor();

    @override
    Future<void> pre(InterceptorContext context) async {}

    @override
    Future<void> post(InterceptorContext context) async {
        if (context.response.body
            case {'data': final Map<String, dynamic> userJson}) {
        final reflector = context.reflect.get<User>();

        final keys = [...userJson.keys];

        for (final key in keys) {
            if (reflector?.get(key) case final ReadOnlyMeta meta) {
            if (meta.has<NoReturn>()) {
                userJson.remove(key);
            }
            }
        }

        context.response.body = {'data': userJson};
        }
    }
}

```
