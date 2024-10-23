# Meta

The `Meta` object is a class that is used to store metadata about an object. There are no limitations on where the `Meta` object can be used. It can be used on your App, Controller, Methods, and even on your custom return types.

## Examples

### Creating a Public Endpoint

A common use case for the `Meta` object is to create a public endpoint that does not require authentication. When you have a controller that requires an `Authorization` header to be present in the request, but you want to allow unauthenticated requests to a specific route.

```dart title="routes/controllers/user_controller.dart"
import 'package:revali_router/revali_router.dart';

@Auth()
@Controller('user')
class UserController {

    @Get()
    Future<PublicUser> publicUser() async {
        return PublicUser(...);
    }
}
```

At the moment, the `publicUser` method requires an `Authorization` header to be present in the request. To allow unauthenticated requests to the `publicUser` method, you can create a `Public` meta class that you can register to the endpoint.

```dart title="lib/meta/public.dart"
import 'package:revali_router/revali_router.dart';

class Public implements Meta {
    const Public();
}
```

Now that we have the `Public` meta class, we can register it to the endpoint.

```dart title="routes/controllers/user_controller.dart"
...
    // highlight-next-line
    @Public()
    @Get()
    Future<PublicUser> publicUser() async {
        return PublicUser(...);
    }
...
```

The final piece to this puzzle is to handle the `Public` meta class in the `Auth` guard.

```dart title="lib/guards/auth_guard.dart"
import 'package:revali_router/revali_router.dart';

class Auth extends Guard {
    const Auth();

    @override
    GuardResult canActivate(context, action) {
        // highlight-start
        if (context.meta.has<Public>()) {
            return action.yes();
        }
        // highlight-end

        ... // Check for Authorization header
    }
}
```

Now, when a request is made to the `publicUser` method, the `Auth` guard will check if the `Public` meta is present in the context and allow the request to continue.

### Removing Sensitive Data from Return Type

When you have a return type that you are returning to the client and contains sensitive data, you can add a `Meta` object to the field of the return type. Leveraging the [`ReflectHandler`][reflect-handler], you can analyze the meta data of the return type's properties and remove the sensitive data before sending it to the client.

```dart title="lib/meta/no_return.dart"
import 'package:revali_router/revali_router.dart';

class AdminEyesOnly extends Meta {
    const AdminEyesOnly();
}
```

Now that we have the `AdminEyesOnly` meta class, we can register it to the field of the endpoint's return type.

```dart title="lib/models/user.dart"
class User {
    const User(
        this.email, {
        required this.isSuperUser,
    });

    final String email;

    // highlight-next-line
    @AdminEyesOnly()
    final bool isSuperUser;
}
```

With the `AdminEyesOnly` meta class registered to the `isSuperUser` field, we can now create an interceptor that will remove the `isSuperUser` field from the response body before sending it to the client.

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
                // highlight-start
                if (meta.has<AdminEyesOnly>()) {
                    userJson.remove(key);
                }
                // highlight-end
            }
        }

        context.response.body = {'data': userJson};
        }
    }
}

```

[reflect-handler]: ./reflect_handler.md
