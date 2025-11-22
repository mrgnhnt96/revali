---
title: Return Types
description: Support for custom return types
sidebar_position: 4
---

# Return Types

Revali Client generates type-safe client code that mirrors your server's return types. It supports a wide range of types out of the box, including primitives, collections, `Future`s, `Stream`s, records, and custom classes.

## Overview

The generated client preserves the exact return types from your server endpoints, ensuring compile-time type safety and automatic serialization/deserialization.

**Supported return types:**

- Primitive types (String, int, double, bool, etc.)
- Collections (List, Set, Map)
- Async types (Future, Stream)
- Nullable types
- Records (named and positional)
- Enums
- Custom classes with JSON serialization
- Generic types

---

## Built-in Type Support

### Primitive Types

All Dart primitive types are automatically supported:

```dart
// Server
@Controller('data')
class DataController {
  @Get('string')
  String getString() => 'Hello, World!';

  @Get('number')
  int getNumber() => 42;

  @Get('decimal')
  double getDecimal() => 3.14;

  @Get('flag')
  bool getFlag() => true;
}
```

**Generated client:**

```dart
abstract class DataDataSource {
  Future<String> getString();
  Future<int> getNumber();
  Future<double> getDecimal();
  Future<bool> getFlag();
}
```

### Collections

Lists, Sets, and Maps are fully supported with type arguments:

```dart
// Server
@Controller('collections')
class CollectionsController {
  @Get('list')
  List<String> getList() => ['a', 'b', 'c'];

  @Get('set')
  Set<int> getSet() => {1, 2, 3};

  @Get('map')
  Map<String, dynamic> getMap() => {'key': 'value'};
}
```

**Generated client:**

```dart
abstract class CollectionsDataSource {
  Future<List<String>> getList();
  Future<Set<int>> getSet();
  Future<Map<String, dynamic>> getMap();
}
```

### Nullable Types

Nullability is preserved in the generated code:

```dart
// Server
@Controller('nullable')
class NullableController {
  @Get('optional')
  String? getOptional() => null;

  @Get('list')
  List<String?> getListWithNulls() => ['a', null, 'c'];
}
```

**Generated client:**

```dart
abstract class NullableDataSource {
  Future<String?> getOptional();
  Future<List<String?>> getListWithNulls();
}
```

### Enums

Enums are automatically serialized as strings:

```dart
// Shared enum
enum Status { pending, active, completed }

// Server
@Controller('status')
class StatusController {
  @Get()
  Status getStatus() => Status.active;
}
```

**Generated client:**

```dart
abstract class StatusDataSource {
  Future<Status> getStatus();
}
```

---

## Async Patterns

### Future

All synchronous server methods are automatically converted to `Future` in the client:

```dart
// Server - synchronous
@Get('user')
User getUser() => User(name: 'Alice');

// Client - asynchronous
Future<User> getUser();
```

Server methods that already return `Future` keep the same signature:

```dart
// Server
@Get('user')
Future<User> getUser() async {
  return await database.getUser();
}

// Client
Future<User> getUser();
```

### Stream

Server endpoints that return `Stream` are preserved in the client:

```dart
// Server
@Get('events')
Stream<Event> getEvents() async* {
  yield Event('start');
  await Future.delayed(Duration(seconds: 1));
  yield Event('end');
}

// Client
Stream<Event> getEvents();
```

**Usage:**

```dart
final events = server.events.getEvents();

await for (final event in events) {
  print('Received: ${event.message}');
}
```

---

## Records

Dart records are fully supported in both positional and named forms:

### Positional Records

```dart
// Server
@Get('coordinates')
(double, double) getCoordinates() {
  return (51.5074, -0.1278); // London coordinates
}

// Client
Future<(double, double)> getCoordinates();
```

**Usage:**

```dart
final (latitude, longitude) = await server.location.getCoordinates();
print('Lat: $latitude, Lon: $longitude');
```

### Named Records

```dart
// Server
@Get('user-info')
({String name, int age}) getUserInfo() {
  return (name: 'Alice', age: 30);
}

// Client
Future<({String name, int age})> getUserInfo();
```

**Usage:**

```dart
final info = await server.user.getUserInfo();
print('${info.name} is ${info.age} years old');
```

### Complex Records

```dart
// Server
@Get('stats')
({int total, List<String> items, bool success}) getStats() {
  return (
    total: 42,
    items: ['a', 'b', 'c'],
    success: true,
  );
}

// Client
Future<({int total, List<String> items, bool success})> getStats();
```

---

## Custom Classes

Custom classes require JSON serialization support to work with Revali Client.

### Serialization Requirements

Every custom class must implement:

1. **`fromJson` factory constructor** - For deserialization
2. **`toJson` method** - For serialization

```dart
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  // Required for deserialization
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  // Required for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
```

### Using JSON Serializable

For complex classes, consider using `json_serializable`:

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

Then run:

```bash
dart run build_runner build
```

---

## Sharing Types Between Server and Client

For custom classes to work in both server and client, they must be in a **shared package**.

### The Problem

If your model is only in the server package:

```text
server_project/
├── lib/
│   └── models/
│       └── user.dart     # ❌ Only in server
└── routes/
    └── user_controller.dart
```

The generated client will reference `User`, but it won't exist in the client project, causing a compile error.

### The Solution

Create a shared package for models:

#### 1. Create the Models Package

```bash
dart create models --template package
```

This creates:

```text
models/
├── lib/
│   └── models.dart
└── pubspec.yaml
```

#### 2. Add Your Models

Move your model classes to the shared package:

```dart title="models/lib/models.dart"
export 'src/user.dart';
export 'src/post.dart';
```

```dart title="models/lib/src/user.dart"
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

#### 3. Add as Dependency to Server

Update your server's `pubspec.yaml`:

```yaml title="server/pubspec.yaml"
dependencies:
  models:
    path: ../models
```

#### 4. Use in Server

```dart title="server/routes/user_controller.dart"
import 'package:models/models.dart';
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UserController {
  @Get()
  List<User> getAll() {
    return [
      User(id: '1', name: 'Alice', email: 'alice@example.com'),
      User(id: '2', name: 'Bob', email: 'bob@example.com'),
    ];
  }

  @Get(':id')
  User getById(@Param('id') String id) {
    return User(id: id, name: 'Alice', email: 'alice@example.com');
  }

  @Post()
  User create(@Body() User user) {
    // Save user
    return user;
  }
}
```

#### 5. Client Generation

When you run `revali dev` or `revali build`, the generated client will automatically:

- Detect the `models` package dependency
- Add it to the generated client's `pubspec.yaml`
- Use the shared types correctly

**Generated client:**

```dart
abstract class UserDataSource {
  Future<List<User>> getAll();
  Future<User> getById({required String id});
  Future<User> create(User user);
}
```

---

## Project Structure Example

Recommended project structure for shared types:

```text
my_project/
├── models/                    # Shared package
│   ├── lib/
│   │   ├── models.dart
│   │   └── src/
│   │       ├── user.dart
│   │       ├── post.dart
│   │       └── comment.dart
│   └── pubspec.yaml
│
├── server/                    # Server package
│   ├── lib/
│   ├── routes/
│   │   ├── user_controller.dart
│   │   ├── post_controller.dart
│   │   └── comment_controller.dart
│   └── pubspec.yaml
│
└── client/                    # Your client app
    ├── lib/
    │   └── main.dart
    └── pubspec.yaml
```

Both `server/pubspec.yaml` and `client/pubspec.yaml` reference `models`:

```yaml
dependencies:
  models:
    path: ../models
```

---

## Generic Types

Generics are preserved in the generated code:

```dart
// Shared generic wrapper
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.success,
    this.message,
  });

  final T data;
  final bool success;
  final String? message;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return ApiResponse(
      data: fromJsonT(json['data']),
      success: json['success'] as bool,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'data': toJsonT(data),
      'success': success,
      'message': message,
    };
  }
}

// Server
@Get('user/:id')
ApiResponse<User> getUser(@Param('id') String id) {
  final user = findUser(id);
  return ApiResponse(
    data: user,
    success: true,
  );
}

// Client
Future<ApiResponse<User>> getUser({required String id});
```

---

## Nested Types

Complex nested types are fully supported:

```dart
// Server
@Get('dashboard')
Map<String, List<User>> getUsersByDepartment() {
  return {
    'Engineering': [User(...), User(...)],
    'Marketing': [User(...), User(...)],
  };
}

// Client
Future<Map<String, List<User>>> getUsersByDepartment();
```

---

## Void Returns

Methods that don't return data use `void`:

```dart
// Server
@Delete('user/:id')
void deleteUser(@Param('id') String id) {
  database.delete(id);
}

// Client
Future<void> deleteUser({required String id});
```

**Usage:**

```dart
await server.user.deleteUser(id: '123');
print('User deleted');
```

---

## Best Practices

### 1. Use a Shared Models Package

Always create a separate package for shared types:

```dart
// ✅ Good - Shared package
models/
  lib/
    models.dart
    src/
      user.dart

// ❌ Bad - Models only in server
server/
  lib/
    models/
      user.dart
```

### 2. Implement JSON Serialization

Always provide `fromJson` and `toJson`:

```dart
// ✅ Good
class User {
  factory User.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

// ❌ Bad - No serialization
class User {
  final String name;
}
```

---

## Common Patterns

### Pagination Response

```dart
// Shared model
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  // JSON serialization...
}

// Server
@Get('users')
PaginatedResponse<User> getUsers(
  @Query('page') int page,
  @Query('size') int size,
) {
  // Fetch paginated users
  return PaginatedResponse(
    items: users,
    total: 1000,
    page: page,
    pageSize: size,
  );
}

// Client usage
final response = await server.user.getUsers(page: 1, size: 20);
print('${response.items.length} of ${response.total} users');
```

---

## Troubleshooting

### Type Not Found Error

**Problem:** Generated client references a type that doesn't exist.

**Solution:** Move the type to a shared package and add it as a dependency to the server.

### Serialization Error

**Problem:** Runtime error during JSON serialization/deserialization.

**Solution:** Ensure your class has `fromJson` and `toJson` methods.

---

## What's Next?

Now that you understand return types, explore these related topics:

- **[Generated Code](/constructs/revali_client/generated-code)** - Understand the client structure
- **[HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors)** - Add request/response handling
- **[Storage](/constructs/revali_client/getting-started/storage)** - Manage cookies and sessions
- **[Configure](/constructs/revali_client/getting-started/configure)** - Customize client generation
