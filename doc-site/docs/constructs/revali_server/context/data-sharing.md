---
description: Share data between lifecycle components during request processing
---

# Data Sharing

The `Data` object provides a way to share data between different [lifecycle components](../lifecycle-components/overview.md) during a single request. It uses type-based storage where the type serves as the key, allowing you to store and retrieve data by its class type.

## Storing Data

Use the `add` method to store data in the context. Each type can only have one instance stored at a time - adding a new instance of the same type will replace the previous one.

```dart
// Store a user object
data.add<User>(user);

// Store a request ID
data.add<String>('req-123');

// Store a custom type
data.add<RequestMetadata>(metadata);
```

:::tip
**Avoid storing primitive types directly.** Instead, create wrapper classes to make your data more meaningful and type-safe.

```dart
class UserId {
  const UserId(this.value);
  final String value;
}

data.add(UserId('1234'));
final userId = data.get<UserId>();
```

:::

## Retrieving Data

Use the `get` method to retrieve stored data. Returns `null` if no data of that type exists.

```dart
// Get a user object
final user = data.get<User>();

// Get a request ID
final requestId = data.get<String>();

// Check if data exists before using it
final user = data.get<User>();
if (user != null) {
  print('User: ${user.name}');
}
```

## Checking Data Existence

Use the `has` method to check if data of a specific type exists, or `contains` to check for a specific value.

```dart
// Check if user data exists
if (data.has<User>()) {
  final user = data.get<User>();
  // Process user data
}

// Check if a specific value is stored
if (data.contains<String>('expected-value')) {
  // Handle specific value case
}
```

## Real-World Example

Here's a common pattern: storing user data from a middleware and accessing it in a guard.

### 1. Store User Data in Middleware

```dart title="lib/components/user_middleware.dart"
import 'package:revali_router/revali_router.dart';

class UserMiddleware implements LifecycleComponent {
  const UserMiddleware({required this.userService});

  final UserService userService;

  MiddlewareResult loadUser(
    Request request,
    Data data,
  ) async {
    final userId = request.pathParameters['userId'];

    if (userId != null) {
      final user = await userService.getUser(userId);
      data.add<User>(user);
    }

    return const MiddlewareResult.next();
  }
}
```

### 2. Access User Data in Guard

```dart title="lib/components/role_guard.dart"
import 'package:revali_router/revali_router.dart';

class UserGuard implements LifecycleComponent {
  const UserGuard();

  GuardResult checkUser(Data data) {
    final user = data.get<User>();

    if (user == null) {
      return const GuardResult.deny(
        statusCode: 401,
        message: 'User not authenticated',
      );
    }

    return const GuardResult.allow();
  }
}
```

### 3. Use in Controller

```dart title="routes/controllers/admin_controller.dart"
import 'package:revali_router/revali_router.dart';

@UserMiddleware()
@UserGuard()
@Controller('admin')
class AdminController {

  @Get('users')
  // User data is available from the middleware
  Future<List<User>> getUsers(@Data() User currentUser) async {
    return await userService.getAllUsers();
  }
}
```

## Best Practices

### Use Meaningful Types

```dart
// ✅ Good - Clear, specific types
data.add<User>(user);
data.add<RequestId>(RequestId.generate());
data.add<SessionData>(sessionData);

// ❌ Avoid - Generic or unclear types
data.add<Object>(someObject); // Too generic
data.add<Map<String, dynamic>>(dataMap); // Unclear structure
```

### Use Wrapper Classes for Primitives

```dart
// ✅ Good - Type-safe primitives
class UserId {
  const UserId(this.value);
  final String value;
}

class RequestId {
  const RequestId(this.value);
  final String value;
}

data.add(UserId('123'));
data.add(RequestId('req-456'));

// ❌ Avoid - Raw primitives
data.add<String>('123'); // What kind of string?
data.add<String>('req-456'); // Ambiguous
```
