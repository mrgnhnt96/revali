# Controllers

Controllers are used to define groups of endpoints/requests. Controllers are long lived, meaning that they are created once, and will be reused through the lifetime of the application.

## Create The Controller

To create a controller, we need to create a class within the `routes` directory

```dart title="routes/users/users_controller.dart"
class UsersController {}
```

In order for Revali to know of this new controller, we need to add the `@Controller` annotation. The `Controller` annotation accepts 1 argument, which is the server path.

```dart title="routes/users/users_controller.dart"
// highlight-next-line
@Controller('users')
class UsersController {}
```

This means that all requests that come through the server that start with `/users` will be routed to this controller.

## Create Endpoints

The endpoints are defined within the newly created controller as methods.

```dart title="routes/users/users_controller.dart"
@Controller('users')
class UsersController {

    // highlight-start
    @Get() // GET /users
    Future<List<User>> getUsers() {
        ...
    }
    // highlight-end

    // highlight-start
    @Get(':id') // GET /users/:id
    Future<User> getUser() {
        ...
    }
    // highlight-end

    // highlight-start
    @Post(':id') // POST /users/:id
    Future<void> saveUser() {
        ...
    }
    // highlight-end
}
```

:::tip
Learn more about [methods]
:::

## Constructors

Revali will pick up the first public constructor within the class and use it to create an instance of the controller.

```dart title="routes/users/users_controller.dart"
class UsersController {
    const UsersController();
    const UsersController._(); // ignored
    const UsersController.test(); // ignored
}
```

:::note
Revali will ignore any private constructors
:::

## Dependencies

Eventually, you will need to use a dependency you've configured. You can add [instance variables][instance-variables] for these dependencies within the constructor and revali_server will supply the appropriate values based on your dependency configuration.

```dart title="routes/users/users_controller.dart"
class UsersController {
    const UsersController(
        this._usersService, {
        required Logger logger,
    }) : _logger = logger;

    final UsersService _usersService;
    final Logger _logger;
}
```

:::important
Since controllers are long lived, they do not have access to the request, so you cannot add any [binding annotations][binding] to any parameters.
:::

:::tip
Learn how to [configure dependencies][configure-dependencies].
:::

[methods]: ./10-methods.md
[configure-dependencies]: ../../../revali/app-configuration/configure-dependencies.md#registering-dependencies
[binding]: ./20-binding.md
[instance-variables]: https://dart.dev/language/constructors#instance-variable-initialization
