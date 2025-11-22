---
description: Transform and validate data from requests
sidebar_position: 4
---

# Pipes

Pipes are data transformation and validation components that process values from [bindings](./binding.md) before they reach your endpoint methods. They're perfect for converting strings to objects, validating data, or performing complex transformations.

:::tip
**Most of the time, you don't need pipes!** Revali automatically detects `fromJson` constructors in your Dart classes. If your class has a `fromJson` factory constructor, Revali will use it automatically for JSON conversion. Only use pipes when you need complex validation, database lookups, or custom transformation logic.
:::

## What Are Pipes?

Think of pipes as **data processors** that:

- **Convert types** - `String "123"` → `int 123`
- **Validate data** - Check if email is valid format
- **Transform objects** - Parse JSON to custom classes
- **Handle errors** - Provide meaningful error messages
- **Perform async operations** - Database lookups, API calls

## Creating Pipes

### Basic Pipe Structure

```dart title="lib/pipes/user_pipe.dart"
import 'package:revali_router/revali_router.dart';

class UserPipe implements Pipe<String, User> {
  const UserPipe({required this.userService});

  final UserService userService;

  @override
  Future<User> transform(String value, Context context) async {
    // Convert string ID to User object
    final user = await userService.getUserById(value);
    if (user == null) {
      throw NotFoundException('User not found: $value');
    }
    return user;
  }
}
```

### Type Parameters

- **First type** (`String`) - What the pipe receives from binding
- **Second type** (`User`) - What the pipe returns to your endpoint

:::tip
Use the CLI to generate pipes quickly:

```bash
dart run revali_server create pipe
```

:::

### Type Conversion Pipe

```dart title="lib/pipes/int_pipe.dart"
import 'package:revali_router/revali_router.dart';

class IntPipe implements Pipe<String, int> {
  const IntPipe();

  @override
  Future<int> transform(String value, Context context) async {
    final intValue = int.tryParse(value);
    if (intValue == null) {
      throw ValidationException('Invalid integer: $value');
    }
    return intValue;
  }
}
```

## Using Pipes

### With Path Parameters

```dart
@Controller('users')
class UsersController {
  @Get(':id')
  Future<User> getUser(@Param.pipe(UserPipe) User user) async {
    return user; // Already a User object
  }
}
```

:::info
Path parameters are defined using `:parameterName` syntax in route paths. Learn more about [creating path parameters](./methods.md#path-parameters) and [extracting them with @Param()](./binding.md#param---path-parameters).
:::

### With Query Parameters

```dart
@Controller('users')
class UsersController {
  @Get()
  Future<List<User>> searchUsers(
    @Query.pipe(EmailPipe) String email,
  ) async {
    return await userService.findByEmail(email);
  }
}
```

### With Request Body

```dart
@Controller('users')
class UsersController {
  @Post()
  Future<User> createUser(@Body.pipe(CreateUserPipe) User user) async {
    return await userService.create(user);
  }
}
```

### Multiple Pipes

```dart
@Controller('users')
class UsersController {
  @Get(':id')
  Future<User> getUser(
    @Param.pipe(IntPipe) int id,
    @Query.pipe(EmailPipe) String email,
  ) async {
    return await userService.getUser(id, email);
  }
}
```

## Context

The `Context` provides access to request information and utilities:

```dart
class CustomPipe implements Pipe<String, String> {
  const CustomPipe();

  @override
  Future<String> transform(String value, Context context) async {
    // Access request data
    final headers = context.request.headers;
    final queryParams = context.request.queryParameters;

    // Log transformation
    context.logger.info('Transforming value: $value');

    // Access data handler
    final currentUser = context.data.get<User>('currentUser');

    return value.toUpperCase();
  }
}
```

:::tip
Learn more about [Context](../context/pipe.md) for advanced usage.
:::

## When to Use Pipes vs `fromJson`

### Use Pipes When

- Complex validation logic
- Database lookups
- Async operations
- Custom error handling
- Multiple transformation steps

### Use `fromJson` When

- Simple JSON parsing
- Synchronous operations
- Standard type conversion

```dart
// Use fromJson for simple cases
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }
}

// Use pipes for complex cases
class UserPipe implements Pipe<String, User> {
  const UserPipe();

  @override
  Future<User> transform(String value, Context context) async {
    // Complex validation, database lookup, etc.
    return await _fetchAndValidateUser(value);
  }
}
```

## What's Next?

Now that you understand pipes, explore these related topics:

1. **[Binding](./binding.md)** - Extract data from requests
2. **[Implied Binding](./implied_binding.md)** - Types that don't need annotations
3. **[HTTP Methods](./methods.md)** - Define endpoint behavior
4. **[Controllers](./controllers.md)** - Organize your endpoints
