---
title: Implied Binding
description: "Types that don't need binding annotations"
---

Some types are automatically detected by Revali and don't require [binding annotations](/constructs/revali_server/core/binding). This makes your code cleaner and reduces boilerplate.

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

For the client IP only, prefer [`@Ip()`](/constructs/revali_server/core/binding#ip---client-ip) instead of reading `request.ip` manually.

<Callout type="warning">

Prefer [binding annotations](/constructs/revali_server/core/binding) and [pipes](/constructs/revali_server/core/pipes) over direct request/response access for better testability and cleaner code.

</Callout>

## Context Providers

These types provide access to request context and metadata:

### Available Context Types

<!-- TODO(mrgnhnt): Update links when docs are updated -->

| Type                                                     | Purpose                         | Use Case                                      |
| -------------------------------------------------------- | ------------------------------- | --------------------------------------------- |
| [`DI`](/revali/app-configuration/configure-dependencies) | Dependency Injection container  | Access all registered dependencies            |
| [`Meta`](../context/meta)                                | Request metadata                | Read/write request metadata                   |
| [`MetaScope`](../context/meta)                           | Request metadata scope          | Access metadata with scope context            |
| [`RouteEntry`](../context/overview)                      | Route information               | Access current route details                  |
| [`Context`](../context/overview)                         | Full request context            | Access complete request context               |
| [`Data`](../context/overview)                            | Data sharing between components | Share data across middleware/guards/endpoints |
| [`CleanUp`](../context/overview)                         | Resource cleanup                | Register cleanup functions                    |
| [`ReflectHandler`](../context/reflect)                   | Reflection utilities            | Access reflection capabilities                |

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

1. **[Binding](/constructs/revali_server/core/binding)** - Extract data with annotations
2. **[Pipes](/constructs/revali_server/core/pipes)** - Transform and validate data
3. **[HTTP Methods](/constructs/revali_server/core/methods)** - Define endpoint behavior and [path parameters](/constructs/revali_server/core/methods#path-parameters)
4. **[Controllers](/constructs/revali_server/core/controllers)** - Organize your endpoints
