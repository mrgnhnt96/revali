# Redirect

The `redirect` function is used to redirect the client to a different URL.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {

    @Redirect('/users/all')
    @Get()
    void users() {
        ...
    }

    @Get('all')
    void allUsers() {
        ...
    }
}
```

In the example above, when a client sends a `GET` request to `/users`, the server redirects the client to `/users/123`. The client then sends a `GET` request to `/users/123`, which is handled by the `user` method.

## Status Code

By default, the status code of the response is `301 Moved Permanently`. This tells the client that the URL has been permanently moved to a different location, the next time the client sends a request to the original URL, it will be redirected to the new URL.

You can change the status code by passing the status code as an argument to the `Redirect` annotation.

```dart
@Redirect('/users/all', 302)
```

## Redirecting to a Different Domain

You can redirect the client to a different domain by passing the domain as an argument to the `Redirect` annotation.

```dart
@Redirect('https://example.com/users/all')
```

## Redirecting to a Different Path

### Within the Same Controller

You can redirect the client to a different path within the same controller by passing the path as an argument to the `Redirect` annotation.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {

    @Redirect('all') // Redirects to /users/all
    @Get()
    void users() {
        ...
    }

    @Get('all')
    void allUsers() {
        ...
    }
}
```

### To a Different Controller

You can redirect the client to a different controller by passing the controller name and path as arguments to the `Redirect` annotation.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {

    @Redirect('/admin/users/all') // Redirects to /admin/users/all
    @Get()
    void users() {
        ...
    }

    @Get('all')
    void allUsers() {
        ...
    }
}
```

:::important
The leading `/` is required when redirecting to a different controller.
:::

:::important
Don't forget to include your app's prefix when redirecting to a different controller.
:::
