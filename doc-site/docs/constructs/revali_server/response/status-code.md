---
title: Status Code
description: Set HTTP status codes to indicate the response status
---

# Response Status Code

> Access via: `context.response.statusCode`

HTTP status codes indicate whether a request was successful or not. Revali automatically sets appropriate status codes, but you can customize them as needed.

## Status Code Categories

HTTP status codes are divided into five categories:

- **1xx** - Informational (100-199)
- **2xx** - Success (200-299)
- **3xx** - Redirection (300-399)
- **4xx** - Client Error (400-499)
- **5xx** - Server Error (500-599)

## Common Status Codes

### Success (2xx)

| Code | Name       | Description          | When to Use                         |
| ---- | ---------- | -------------------- | ----------------------------------- |
| 200  | OK         | Request successful   | Default for successful GET requests |
| 201  | Created    | Resource created     | After successful POST requests      |
| 204  | No Content | Success with no body | When no response data is needed     |

### Client Error (4xx)

| Code | Name                 | Description             | When to Use                         |
| ---- | -------------------- | ----------------------- | ----------------------------------- |
| 400  | Bad Request          | Invalid request         | Malformed request data              |
| 401  | Unauthorized         | Authentication required | Missing or invalid credentials      |
| 403  | Forbidden            | Access denied           | Valid credentials but no permission |
| 404  | Not Found            | Resource not found      | Requested resource doesn't exist    |
| 405  | Method Not Allowed   | HTTP method not allowed | Wrong HTTP method for endpoint      |
| 422  | Unprocessable Entity | Validation failed       | Request data validation errors      |

### Server Error (5xx)

| Code | Name                  | Description                     | When to Use                      |
| ---- | --------------------- | ------------------------------- | -------------------------------- |
| 500  | Internal Server Error | Server error                    | Unexpected server errors         |
| 501  | Not Implemented       | Feature not implemented         | Endpoint not yet implemented     |
| 503  | Service Unavailable   | Service temporarily unavailable | Server overloaded or maintenance |

## Default Status Codes

Revali automatically sets these status codes:

- **200** - Endpoint executed successfully
- **400** - Middleware halted the request
- **403** - Guard blocked the request
- **404** - Endpoint not found
- **405** - HTTP method not allowed
- **500** - Exception was thrown

## Setting Status Codes

### Via Annotations (Recommended)

Set status codes statically using the `@StatusCode` annotation:

```dart
@Controller('api')
class ApiController {
  @Post('users')
  @StatusCode(201)
  User createUser(@Body() CreateUserRequest request) {
    return userService.createUser(request);
  }

  @Delete('users/:id')
  @StatusCode(204)
  void deleteUser(@Param() String id) {
    userService.deleteUser(id);
  }
}
```

### Via Lifecycle Components

Set status codes dynamically in interceptors:

```dart
class StatusCodeProcessor implements LifecycleComponent {
  InterceptorPostResult processResponse(Response response) {
    final data = response.body.data;

    // Set different status codes based on response data
    if (data == null) {
      response.statusCode = 404;
    } else if (data is Map && data.containsKey('error')) {
      response.statusCode = 400;
    } else {
      response.statusCode = 200;
    }

    return const InterceptorPostResult.next();
  }
}
```

### Via Binding (Not Recommended)

```dart
@Controller('api')
class ApiController {
  @Get('data')
  void getData(Response response) {
    response.statusCode = 200;
    response.body = {'message': 'Success'};
  }
}
```

:::warning
**Avoid using `Response` in endpoint methods.** Use annotations or lifecycle components instead to keep endpoints clean and focused.
:::

## Common Patterns

### Success Responses

```dart
@Controller('api')
class ApiController {
  @Get('users')
  @StatusCode(200)
  List<User> getUsers() {
    return userService.getAllUsers();
  }

  @Post('users')
  @StatusCode(201)
  User createUser(@Body() CreateUserRequest request) {
    return userService.createUser(request);
  }

  @Put('users/:id')
  @StatusCode(200)
  User updateUser(@Param() String id, @Body() UpdateUserRequest request) {
    return userService.updateUser(id, request);
  }

  @Delete('users/:id')
  @StatusCode(204)
  void deleteUser(@Param() String id) {
    userService.deleteUser(id);
  }
}
```

### Error Responses

```dart
@Controller('api')
class ApiController {
  @Get('users/:id')
  User getUser(@Param() String id) {
    final user = userService.findById(id);
    if (user == null) {
      throw ServerException(
        statusCode: 404,
        body: 'User not found',
      );
    }
    return user;
  }

  @Post('users')
  User createUser(@Body() CreateUserRequest request) {
    try {
      return userService.createUser(request);
    } catch (e) {
      throw ServerException(
        statusCode: 422,
        body: 'Validation failed ${e.toString()}',
      );
    }
  }
}
```

### Conditional Status Codes

```dart
class ConditionalStatusCodes implements LifecycleComponent {
  InterceptorPostResult processResponse(Response response) {
    final data = response.body.data;

    if (data is Map) {
      if (data.containsKey('created')) {
        response.statusCode = 201;
      } else if (data.containsKey('updated')) {
        response.statusCode = 200;
      } else if (data.containsKey('deleted')) {
        response.statusCode = 204;
      }
    }

    return const InterceptorPostResult.next();
  }
}
```

## Best Practices

### Use Annotations for Static Status Codes

```dart
// ✅ Good - Clear and static
@Post('users')
@StatusCode(201)
User createUser(@Body() CreateUserRequest request) {
  return userService.createUser(request);
}

// ❌ Avoid - Unnecessary complexity for static values
@Post('users')
User createUser(@Body() CreateUserRequest request, Response response) {
  response.statusCode = 201;
  return userService.createUser(request);
}
```

### Use Exceptions for Error Status Codes

```dart
// ✅ Good - Clear error handling
@Get('users/:id')
User getUser(@Param() String id) {
  final user = userService.findById(id);
  if (user == null) {
    throw ServerException(statusCode: 404, body: 'User not found');
  }
  return user;
}

// ❌ Avoid - Manual status code setting
@Get('users/:id')
void getUser(@Param() String id, Response response) {
  final user = userService.findById(id);
  if (user == null) {
    response.statusCode = 404;
    response.body = {'error': 'User not found'};
  } else {
    response.statusCode = 200;
    response.body = user;
  }
}
```

### Use Lifecycle Components for Dynamic Status Codes

```dart
// ✅ Good - Dynamic based on response data
class StatusCodeProcessor implements LifecycleComponent {
  InterceptorPostResult processResponse(Response response) {
    final data = response.body.data;

    if (data is Map && data.containsKey('error')) {
      response.statusCode = 400;
    }

    return const InterceptorPostResult.next();
  }
}
```

## What's Next?

- Learn about [response body](./body.md) for setting response data
- Explore [response headers](./headers.md) for HTTP headers
- See [cookies](./cookies.md) for session management
- Check out [WebSockets](./websockets.md) for real-time communication
