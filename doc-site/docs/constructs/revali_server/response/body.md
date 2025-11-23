---
title: Body
description: Set the response payload sent to the client
---

# Response Body

> Access via: `context.response.body`

The response body contains the data sent to the client. Revali automatically handles serialization and wraps your data in a consistent structure.

## Default Wrapping

Revali automatically wraps your response data in a `data` key for consistency:

```dart
@Controller('api')
class ApiController {
  @Get('count')
  int getCount() {
    return 42;
  }
}
```

**Response:**

```json
{
  "data": 42
}
```

## Supported Types

### Primitives

```dart
@Controller('api')
class ApiController {
  @Get('message')
  String getMessage() {
    return 'Hello World';
  }

  @Get('count')
  int getCount() {
    return 42;
  }

  @Get('active')
  bool isActive() {
    return true;
  }
}
```

**Responses:**

```json
{"data": "Hello World"}
{"data": 42}
{"data": true}
```

### Custom Objects

Return custom objects with `toJson()` method:

```dart
class User {
  const User({required this.name, required this.email});

  final String name;
  final String email;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
    };
  }
}

@Controller('api')
class ApiController {
  @Get('user')
  User getUser() {
    return const User(name: 'John Doe', email: 'john@example.com');
  }
}
```

**Response:**

```json
{
  "data": {
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Collections

```dart
@Controller('api')
class ApiController {
  @Get('users')
  List<User> getUsers() {
    return [
      const User(name: 'John', email: 'john@example.com'),
      const User(name: 'Jane', email: 'jane@example.com'),
    ];
  }

  @Get('settings')
  Map<String, dynamic> getSettings() {
    return {
      'theme': 'dark',
      'notifications': true,
    };
  }
}
```

**Responses:**

```json
{
  "data": [
    { "name": "John", "email": "john@example.com" },
    { "name": "Jane", "email": "jane@example.com" }
  ]
}
```

## Raw Content

### Plain Text

Use `StringContent` to return raw text without JSON wrapping:

```dart
@Controller('api')
class ApiController {
  @Get('text')
  StringContent getText() {
    return StringContent('Hello World');
  }
}
```

**Response:**

```
Hello World
```

### HTML Content

```dart
@Controller('api')
class ApiController {
  @Get('page')
  StringContent getPage() {
    return StringContent('''
      <html>
        <body>
          <h1>Hello World</h1>
        </body>
      </html>
    ''');
  }
}
```

## File Responses

### Local Files

Return `File` objects for file downloads:

```dart
import 'dart:io';

@Controller('files')
class FileController {
  @Get('download')
  File downloadFile() {
    return File('path/to/file.pdf');
  }
}
```

### Memory Files

Create files from content in memory:

```dart
@Controller('files')
class FileController {
  @Get('generate')
  MemoryFile generateFile() {
    return MemoryFile.from(
      'Generated content',
      mimeType: 'text/plain',
      basename: 'document',
      extension: 'txt',
    );
  }
}
```

### Stream Files

Stream large files efficiently:

```dart
@Controller('files')
class FileController {
  @Get('stream')
  Stream<List<int>> streamFile() {
    return File('large-file.zip').openRead();
  }
}
```

## Error Responses

:::tip
**Global Error Handling:** For application-wide error handling, use the [exception catcher](../lifecycle-components/advanced/exception-catchers.md) to centralize error processing and response formatting.
:::

### Using Exceptions

Throw exceptions for error responses:

```dart
@Controller('api')
class ApiController {
  @Get('user/:id')
  User getUser(@Param() String id) {
    final user = userService.findById(id);
    if (user == null) {
      throw NotFoundException('User not found');
    }
    return user;
  }
}
```

## Setting Body in Lifecycle Components

### Interceptors

Modify response body in interceptors:

```dart
class ResponseProcessor implements LifecycleComponent {
  InterceptorPostResult processResponse(Response response) {
    final data = response.body.data;

    // Add metadata to response
    response.body = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    return const InterceptorPostResult.next();
  }
}
```

### Middleware

```dart
class LoggingMiddleware implements LifecycleComponent {
  MiddlewareResult processRequest(Response response) {
    // Set default response if needed
    if (response.body.data == null) {
      response.body = {'message': 'No data available'};
    }

    return const MiddlewareResult.next();
  }
}
```

## Best Practices

### Use Return Values

```dart
// ✅ Good - Clean and simple
@Get('users')
List<User> getUsers() {
  return userService.getAllUsers();
}

// ❌ Avoid - Unnecessary complexity
@Get('users')
void getUsers(Response response) {
  response.body = userService.getAllUsers();
}
```

### Implement toJson

```dart
// ✅ Good - Proper serialization
class User {
  const User({required this.name, required this.email});

  final String name;
  final String email;

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email};
  }
}

// ❌ Avoid - No serialization method
class User {
  const User({required this.name, required this.email});

  final String name;
  final String email;
}
```

### Throw Exceptions for Error Responses

```dart
@Get('user/:id')
User getUser(@Param() String id) {
  final user = userService.findById(id);
  if (user == null) {
    throw NotFoundException('User not found');
  }
  return user;
}
```

## What's Next?

- Learn about [response headers](./headers.md) for HTTP headers
- Explore [status codes](./status-code.md) for HTTP status codes
- See [cookies](./cookies.md) for session management
- Check out [WebSockets](./websockets.md) for real-time communication
