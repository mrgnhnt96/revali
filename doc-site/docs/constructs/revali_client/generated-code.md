---
title: Generated Code
description: The structure of the generated client code
sidebar_position: 1
---

# Structure of the Generated Client Code

The Revali Client generates well-structured, idiomatic Dart code designed to interact with your Revali server. All generated code adheres to SOLID principles, promoting separation of concerns, testability, and long-term maintainability.

## Overview

At the heart of the client lies the `Server` class — the primary entry point for accessing backend functionality. For each server-side controller, a corresponding _data source_ is generated on the client side. This includes:

- An **interface** that defines the available methods and types
- An **implementation** that handles request construction, network calls, and response parsing

This architecture ensures your client code is type-safe, testable, and follows clean architecture patterns.

---

## Project Structure

Generated files are stored under the `.revali/revali_client/` directory and follow a clean modular structure:

```text
.revali/
└── revali_client/
    ├── lib/
    │   ├── client.dart           # All generated implementations
    │   ├── interfaces.dart       # All generated interfaces
    │   └── src/
    │       ├── server.dart       # The main Server class
    │       ├── impls/
    │       │   ├── user_data_source_impl.dart
    │       │   ├── post_data_source_impl.dart
    │       │   └── auth_data_source_impl.dart
    │       └── interfaces/
    │           ├── user_data_source.dart
    │           ├── post_data_source.dart
    │           └── auth_data_source.dart
    └── pubspec.yaml
```

### Import Structure

You only need to import two files to use the generated code:

```dart
import 'package:revali_client/client.dart';      // For implementations
import 'package:revali_client/interfaces.dart';  // For type definitions
```

The `client.dart` file exports:

- The `Server` class
- All data source implementations
- The underlying HTTP client

The `interfaces.dart` file exports:

- All data source interface definitions
- Shared models and types

---

## The Server Class

The `Server` class is the main entry point for your client. It exposes a field for each data source, one per controller. Each field:

- Is typed using the interface (e.g., `UserDataSource`)
- Returns the implementation (e.g., `UserDataSourceImpl`)

This design inverts the dependency flow and enables client code to depend on abstractions — not implementations.

### Basic Example

```dart
import 'package:revali_client/client.dart';
import 'package:revali_client/interfaces.dart';

void main() async {
  // Create the server instance
  final server = Server();

  // Access data sources through interfaces
  final UserDataSource users = server.user;
  final PostDataSource posts = server.post;

  // Make type-safe API calls
  final allUsers = await users.getAll();
  final user = await users.getById(id: '123');
}
```

### Server Class Initialization

The `Server` class can be customized during initialization:

```dart
final server = Server(
  // Provide custom storage for cookies and session data
  storage: MyCustomStorage(),

  // Add HTTP interceptors for logging, auth, etc.
  interceptors: [
    LoggingInterceptor(),
    AuthInterceptor(),
  ],

  // Provide a custom HTTP client
  client: MyCustomHttpClient(),
);
```

:::tip
Learn more about [Storage](/constructs/revali_client/getting-started/storage) and [HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors).
:::

---

## Data Sources

For each controller in your server, Revali Client generates a corresponding data source consisting of an interface and implementation.

### Naming Convention

Data sources follow a predictable naming pattern based on the controller name:

| Controller Name  | Interface Name   | Implementation Name  | Server Property |
| ---------------- | ---------------- | -------------------- | --------------- |
| `UserController` | `UserDataSource` | `UserDataSourceImpl` | `server.user`   |
| `PostController` | `PostDataSource` | `PostDataSourceImpl` | `server.post`   |
| `AuthController` | `AuthDataSource` | `AuthDataSourceImpl` | `server.auth`   |

The server property name is the camelCase version of the controller name without the "Controller" suffix.

### Generated Interface

Given this server controller:

```dart title="routes/user_controller.dart"
@Controller('users')
class UserController {
  @Get()
  Future<List<User>> getAll() async {
    return await userService.getAllUsers();
  }

  @Get(':id')
  Future<User> getById(@Param('id') String id) async {
    return await userService.getUserById(id);
  }

  @Post()
  Future<User> create(@Body() User user) async {
    return await userService.createUser(user);
  }

  @Delete(':id')
  Future<void> delete(@Param('id') String id) async {
    await userService.deleteUser(id);
  }
}
```

Revali Client generates this interface:

```dart title=".revali/revali_client/lib/src/interfaces/user_data_source.dart"
abstract class UserDataSource {
  /// GET /api/users
  Future<List<User>> getAll();

  /// GET /api/users/:id
  Future<User> getById({required String id});

  /// POST /api/users
  Future<User> create(User user);

  /// DELETE /api/users/:id
  Future<void> delete({required String id});
}
```

### Generated Implementation

The corresponding implementation handles all the HTTP details:

```dart title=".revali/revali_client/lib/src/impls/user_data_source_impl.dart"
class UserDataSourceImpl implements UserDataSource {
  const UserDataSourceImpl(this._client);

  final RevaliClient _client;

  @override
  Future<List<User>> getAll() async {
    final request = HttpRequest(
      method: 'GET',
      path: '/api/users',
    );

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw ServerException.fromResponse(response);
    }

    return (response.body as List)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<User> getById({required String id}) async {
    final request = HttpRequest(
      method: 'GET',
      path: '/api/users/$id',
    );

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw ServerException.fromResponse(response);
    }

    return User.fromJson(response.body as Map<String, dynamic>);
  }

  @override
  Future<User> create(User user) async {
    final request = HttpRequest(
      method: 'POST',
      path: '/api/users',
      body: user.toJson(),
    );

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw ServerException.fromResponse(response);
    }

    return User.fromJson(response.body as Map<String, dynamic>);
  }

  @override
  Future<void> delete({required String id}) async {
    final request = HttpRequest(
      method: 'DELETE',
      path: '/api/users/$id',
    );

    final response = await _client.send(request);

    if (response.statusCode != 204) {
      throw ServerException.fromResponse(response);
    }
  }
}
```

:::note
The implementation is fully generated and should not be modified manually. Any changes will be overwritten on the next build.
:::

---

## Method Parameters

Revali Client correctly maps all parameter types from your server endpoints:

### Path Parameters

Path parameters are converted to named parameters:

```dart
// Server
@Get(':id')
Future<User> getUser(@Param('id') String id) async { ... }

// Generated Client
Future<User> getUser({required String id});
```

### Query Parameters

Query parameters are also mapped to named parameters:

```dart
// Server
@Get()
Future<List<User>> search(@Query('name') String? name) async { ... }

// Generated Client
Future<List<User>> search({String? name});
```

### Request Body

Body parameters are passed as positional parameters:

```dart
// Server
@Post()
Future<User> create(@Body() User user) async { ... }

// Generated Client
Future<User> create(User user);
```

### Headers

Headers are mapped to named parameters:

```dart
// Server
@Get()
Future<User> getCurrent(@Header('Authorization') String token) async { ... }

// Generated Client
Future<User> getCurrent({required String authorization});
```

---

## Error Handling

All generated methods automatically handle HTTP errors by throwing a `ServerException`:

```dart
try {
  final user = await server.user.getById(id: '123');
} on ServerException catch (e) {
  print('Error ${e.statusCode}: ${e.message}');
  print('Body: ${e.body}');
}
```

The `ServerException` class provides:

- `statusCode`: The HTTP status code (e.g., 404, 500)
- `message`: A human-readable error message
- `body`: The raw response body
- `headers`: Response headers

### Custom Error Handling

You can use HTTP interceptors to customize error handling globally:

```dart
class ErrorInterceptor implements HttpInterceptor {
  @override
  FutureOr<void> onResponse(HttpResponse response) async {
    if (response.statusCode >= 400) {
      // Log error, show notification, etc.
      print('API Error: ${response.statusCode}');
    }
  }
}

final server = Server(
  interceptors: [ErrorInterceptor()],
);
```

---

## Testing with Generated Code

The interface-based design makes testing straightforward. You can easily create mock implementations:

### Creating a Mock

```dart
class MockUserDataSource implements UserDataSource {
  @override
  Future<List<User>> getAll() async {
    return [
      User(id: '1', name: 'Test User 1'),
      User(id: '2', name: 'Test User 2'),
    ];
  }

  @override
  Future<User> getById({required String id}) async {
    return User(id: id, name: 'Test User');
  }

  @override
  Future<User> create(User user) async {
    return user.copyWith(id: 'generated-id');
  }

  @override
  Future<void> delete({required String id}) async {
    // Mock implementation
  }
}
```

### With Dependency Injection

```dart
class UserRepository {
  UserRepository(this.dataSource);

  final UserDataSource dataSource;

  Future<List<User>> getAllUsers() => dataSource.getAll();
}

void main() {
  test('repository uses data source', () async {
    final repository = UserRepository(MockUserDataSource());
    final users = await repository.getAllUsers();

    expect(users, isNotEmpty);
  });
}
```

---

## Type Safety and Serialization

### Automatic Serialization

The generated code automatically handles JSON serialization and deserialization:

```dart
// Request body serialization
final user = User(name: 'Alice', email: 'alice@example.com');
await server.user.create(user); // Automatically calls user.toJson()

// Response deserialization
final users = await server.user.getAll(); // Automatically parses JSON to List<User>
```

### Requirements for Custom Types

For custom types to work with the generated client, they must:

1. Have a `fromJson` factory constructor:

   ```dart
   factory User.fromJson(Map<String, dynamic> json) => User(...);
   ```

2. Have a `toJson` method:

   ```dart
   Map<String, dynamic> toJson() => {...};
   ```

:::tip
Learn more about sharing custom types in the [Return Types](/constructs/revali_client/getting-started/return-types) guide.
:::

---

## Benefits of This Architecture

### 🧪 **Testability**

The interface-implementation split makes it trivial to:

- Create mock implementations for testing
- Swap implementations without changing client code
- Test business logic in isolation

### 🔒 **Type Safety**

Every API call is:

- Fully type-checked at compile time
- Protected against typos and parameter errors
- Backed by your server's actual implementation

### 🧹 **Clean Code**

The generated code:

- Follows SOLID principles
- Maintains clear separation of concerns
- Enables dependency injection
- Promotes clean architecture patterns

### 🔄 **Automatic Synchronization**

When you change your server:

- Client code automatically regenerates
- Type errors appear at compile time
- No manual updates needed

### 📦 **Zero Boilerplate**

You never write:

- HTTP request construction
- URL path building
- JSON serialization/deserialization
- Error parsing

---

## Next Steps

- **[Return Types](/constructs/revali_client/getting-started/return-types)** - Learn about custom data types
- **[HTTP Interceptors](/constructs/revali_client/getting-started/http-interceptors)** - Add request/response handling
- **[Storage](/constructs/revali_client/getting-started/storage)** - Persist cookies and session data
- **[get_it Integration](/constructs/revali_client/integrations/get_it)** - Use with dependency injection
