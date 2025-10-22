---
description: Organize your API endpoints with controllers
sidebar_position: 0
---

# Controllers

Controllers are the foundation of your API architecture. They organize related endpoints, handle business logic, and provide a clean way to structure your server-side code.

## What Are Controllers?

Think of controllers as **traffic directors** for your API. They:

- **Group related endpoints** together (like all user-related operations)
- **Handle business logic** for those endpoints
- **Manage dependencies** and services
- **Provide a clean separation** between routing and logic

## Creating Your First Controller

### Method 1: Using the CLI (Recommended)

The fastest way to create a controller is using the CLI:

```bash
dart run revali_server create controller
```

When prompted, enter a name like `users` or `products`. This generates a complete controller with examples.

### Method 2: Manual Creation

Create a new file in your `routes` directory:

```dart title="routes/controllers/users_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  // Your endpoints will go here
}
```

**Key points:**

- File must end with `_controller.dart` or `.controller.dart`
- Must be in the `routes` directory
- Use the `@Controller('path')` annotation to define the base route

## Understanding Routes

The `@Controller('users')` annotation means:

- All endpoints in this controller start with `/users`
- `@Get()` becomes `GET /users`
- `@Get(':id')` becomes `GET /users/:id`
- `@Post()` becomes `POST /users`

## Adding Endpoints

Endpoints are methods within your controller:

```dart title="routes/controllers/users_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {

  @Get()
  Future<List<User>> getUsers() async {
    // Return all users
    return await userService.getAllUsers();
  }

  @Get(':id')
  Future<User> getUser(@Param() String id) async {
    // Return specific user
    return await userService.getUserById(id);
  }

  @Post()
  Future<User> createUser(@Body() CreateUserRequest request) async {
    // Create new user
    return await userService.createUser(request);
  }

  @Put(':id')
  Future<User> updateUser(
    @Param() String id,
    @Body() UpdateUserRequest request,
  ) async {
    // Update existing user
    return await userService.updateUser(id, request);
  }

  @Delete(':id')
  Future<void> deleteUser(@Param() String id) async {
    // Delete user
    await userService.deleteUser(id);
  }
}
```

**Available routes:**

- `GET /users` → Get all users
- `GET /users/:id` → Get specific user
- `POST /users` → Create new user
- `PUT /users/:id` → Update user
- `DELETE /users/:id` → Delete user

## Constructor and Dependencies

Controllers can have dependencies injected through their constructor:

```dart title="routes/controllers/users_controller.dart"
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController(
    this._userService,
    this._logger,
  );

  final UserService _userService;
  final Logger _logger;

  @Get()
  Future<List<User>> getUsers() async {
    _logger.info('Fetching all users');
    return await _userService.getAllUsers();
  }
}
```

**Important notes:**

- Revali uses the **first public constructor**
- Private constructors are ignored
- Dependencies are automatically injected based on your configuration
- Controllers don't have access to request objects directly

## Controller Lifespan

### Singleton (Default)

By default, controllers are created once and reused:

```dart
@Controller('users')
class UsersController {
  // Created once, reused for all requests
}
```

### Factory (Per Request)

Create a new instance for each request:

```dart
@Controller('users', type: InstanceType.factory)
class UsersController {
  // New instance created for each request
}
```

## Best Practices

### Keep Controllers Focused

```dart
// ✅ Good - focused on user operations
@Controller('users')
class UsersController {
  @Get()
  Future<List<User>> getUsers() => _userService.getAllUsers();

  @Post()
  Future<User> createUser(@Body() CreateUserRequest request) =>
    _userService.createUser(request);
}

// ❌ Avoid - mixing unrelated operations
@Controller('users')
class UsersController {
  @Get()
  Future<List<User>> getUsers() => _userService.getAllUsers();

  @Get()
  Future<List<Product>> getProducts() => _productService.getAllProducts(); // Wrong!
}
```

## What's Next?

Now that you understand controllers, explore these related topics:

1. **[HTTP Methods](./methods.md)** - Learn about different HTTP methods and how to use them
2. **[Binding](./binding.md)** - Understand how to extract data from requests
3. **[Pipes](./pipes.md)** - Transform and validate request data
4. **[Dependency Injection](../../../revali/app-configuration/configure-dependencies.md)** - Configure your services and dependencies

Ready to dive deeper? Let's explore HTTP methods!
