---
description: Types that don't need binding annotations
sidebar_position: 3
---

# Implied Binding

Some types are automatically detected by Revali and don't require [binding annotations](./binding.md). This makes your code cleaner and reduces boilerplate.

## What Is Implied Binding?

Implied binding means Revali automatically knows how to provide certain types to your endpoints and controllers without explicit annotations. You can use these types directly as parameters.

## Request/Response Objects

### Response Objects

```dart
@Controller('api')
class ApiController {
  @Get('custom')
  String getCustom(Headers headers) {
    headers['X-Custom-Header'] = 'My Value';
    return 'Custom response';
  }
}
```

| Type                           | Purpose                        | When to Use                |
| ------------------------------ | ------------------------------ | -------------------------- |
| `Headers` or `ResponseHeaders` | Read & Modify response headers | Manage response headers    |
| `Cookies` or `ResponseCookies` | Read & Modify response cookies | Manage response cookies    |
| `SetCookies`                   | Set response cookies           | Setting custom cookies     |
| `Response`                     | Full response control          | Advanced response handling |

### Request Objects

```dart
@Controller('api')
class ApiController {
  @Get('debug')
  String debug(Request request) {
    return 'Method: ${request.method}, Path: ${request.path}';
  }
}
```

| Type             | Purpose              | When to Use        |
| ---------------- | -------------------- | ------------------ |
| `Request`        | Read request data    | Debugging, logging |
| `RequestHeaders` | Read request headers | Header inspection  |
| `RequestCookies` | Read request cookies | Cookie inspection  |

:::warning
Prefer [binding annotations](./binding.md) and [pipes](./pipes.md) over direct request/response access for better testability and cleaner code.
:::

## Context Providers

These types provide access to request context and metadata:

### Available Context Types

<!-- TODO(mrgnhnt): Update links when docs are updated -->

| Type                                                     | Purpose                         | Use Case                                      |
| -------------------------------------------------------- | ------------------------------- | --------------------------------------------- |
| [`DI`](/revali/app-configuration/configure-dependencies) | Dependency Injection container  | Access all registered dependencies            |
| [`Meta`](../context/core/meta)                           | Request metadata                | Read/write request metadata                   |
| [`MetaScope`](../context/core/meta)                      | Request metadata scope          | Access metadata with scope context            |
| [`RouteEntry`](../context/core/context)                  | Route information               | Access current route details                  |
| [`Context`](../context/core/context)                     | Full request context            | Access complete request context               |
| [`Data`](../context/core/context)                        | Data sharing between components | Share data across middleware/guards/endpoints |
| [`CleanUp`](../context/core/context)                     | Resource cleanup                | Register cleanup functions                    |
| [`ReflectHandler`](../context/core/reflect_handler)      | Reflection utilities            | Access reflection capabilities                |

## Best Practices

### Use Implied Types When Appropriate

```dart
// ✅ Good - using implied binding for context
@Controller('api')
class ApiController {
  @Get('status')
  String getStatus(Meta meta) {
    return 'Request to ${meta.request.path} at ${DateTime.now()}';
  }
}

// ✅ Good - using binding for data extraction
@Controller('users')
class UsersController {
  @Get(':id')
  String getUser(@Param() String id) {
    return 'User ID: $id';
  }
}
```

### Avoid Overusing Low-Level Types

```dart
// ❌ Avoid - too much low-level access
@Controller('api')
class ApiController {
  @Get('data')
  String getData(
    Request request,
    ReadOnlyHeaders headers,
    ReadOnlyBody body,
    MutableResponse response,
  ) {
    // Too much manual work!
  }
}

// ✅ Better - use bindings and pipes
@Controller('api')
class ApiController {
  @Get('data')
  String getData(
    @Body() MyData data,
    @Header('Authorization') String? auth,
  ) {
    // Clean and testable
  }
}
```

### Combine Implied and Explicit Binding

```dart
@Controller('users')
class UsersController {
  @Get('profile')
  String getProfile(
    @Param() String id,           // Explicit binding
    Data data,            // Implied binding
    @Dep() UserService service,   // Explicit binding
  ) {
    final currentUser = data.get<User>('currentUser');
    return service.getUserProfile(id, currentUser);
  }
}
```

## What's Next?

Now that you understand implied binding, you have a complete picture of Revali's data handling:

1. **[Binding](./binding.md)** - Extract data with annotations
2. **[Pipes](./pipes.md)** - Transform and validate data
3. **[HTTP Methods](./methods.md)** - Define endpoint behavior and [path parameters](./methods.md#path-parameters)
4. **[Controllers](./controllers.md)** - Organize your endpoints
