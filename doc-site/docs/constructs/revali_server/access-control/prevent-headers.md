---
description: Block specific headers from being used in requests
---

# Prevent Headers

## What Are Prevent Headers?

Prevent Headers is a security mechanism that blocks specific headers from being used in HTTP requests. Unlike CORS headers that allow certain headers, Prevent Headers explicitly denies the use of specified headers, providing an additional layer of security for your API.

### Why Use Prevent Headers?

Prevent Headers help protect your API by:

- **Blocking sensitive headers** that could expose internal information
- **Preventing header injection attacks** by denying malicious headers
- **Controlling client behavior** by restricting which headers can be sent
- **Adding security layers** beyond standard CORS protection

### How Prevent Headers Work

When a client sends a request with a header that's in the prevent list, the server will reject the request. This happens before any endpoint logic is executed, providing early protection against unwanted header usage.

## Using Prevent Headers

### Basic Usage

Use the `@PreventHeaders` annotation to block specific headers:

```dart
import 'package:revali_router/revali_router.dart';

@PreventHeaders({'X-Sensitive-Header', 'X-Internal-Data'})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data without sensitive headers';
  }
}
```

### Scoping

Prevent Headers can be applied at different levels:

- **App level** - Applies to all controllers and endpoints
- **Controller level** - Applies to all endpoints in the controller
- **Endpoint level** - Applies only to specific endpoints

```dart
@PreventHeaders({'X-Global-Blocked'})
@App()
class MyApp {
  // All controllers inherit X-Global-Blocked prevention
}

@PreventHeaders({'X-Controller-Blocked'})
@Controller('users')
class UsersController {
  // Inherits X-Global-Blocked and adds X-Controller-Blocked

  @PreventHeaders({'X-Endpoint-Blocked'})
  @Get('profile')
  String getProfile() {
    // Blocks X-Global-Blocked, X-Controller-Blocked, and X-Endpoint-Blocked
  }
}
```

:::tip
Learn more about [scoping in lifecycle components](../lifecycle-components/overview.md#scoping).
:::

### Inheritance

By default, `@PreventHeaders` is inherited by child controllers and endpoints. This means that headers blocked at the app level will also be blocked in all controllers and endpoints within that app.

```dart
@PreventHeaders({'X-Parent-Header'})
@Controller('prevent-headers')
class PreventHeadersController {
  const PreventHeadersController();

  @Get('inherited')
  String inherited() {
    // This endpoint blocks X-Parent-Header (inherited from controller)
    return 'Hello world!';
  }
}
```

### Disabling Inheritance

Use `@PreventHeaders.noInherit()` to prevent inheritance of parent-level blocked headers:

```dart
@PreventHeaders({'X-Parent-Header'})
@Controller('prevent-headers')
class PreventHeadersController {
  const PreventHeadersController();

  @PreventHeaders.noInherit({'X-My-Header'})
  @Get('not-inherited')
  String notInherited() {
    // This endpoint only blocks X-My-Header
    // X-Parent-Header is NOT blocked (inheritance disabled)
    return 'Hello world!';
  }
}
```

### Combining Headers

You can combine inherited and local blocked headers:

```dart
@PreventHeaders({'X-Parent-Header'})
@Controller('prevent-headers')
class PreventHeadersController {
  const PreventHeadersController();

  @PreventHeaders({'X-My-Header'})
  @Get('combined')
  String combined() {
    // This endpoint blocks both X-Parent-Header (inherited) and X-My-Header (local)
    return 'Hello world!';
  }
}
```

## Common Use Cases

### Blocking Sensitive Headers

```dart
@PreventHeaders({'X-Internal-Data', 'X-Debug-Info', 'X-Secret-Key'})
@Controller('api')
class ApiController {
  @Get('public-data')
  String getPublicData() {
    return 'Safe public data';
  }
}
```

### Preventing Header Injection

```dart
@PreventHeaders({'X-Forwarded-For', 'X-Real-IP', 'X-Original-IP'})
@Controller('admin')
class AdminController {
  @Get('sensitive')
  String getSensitiveData() {
    return 'Admin data without IP spoofing headers';
  }
}
```

### API Version Control

```dart
@PreventHeaders({'X-API-Version-1', 'X-Deprecated-Header'})
@Controller('v2')
class V2Controller {
  @Get('data')
  String getData() {
    return 'V2 API response';
  }
}
```

## Error Handling

When a client sends a request with a blocked header, the server will:

1. **Reject the request** before it reaches your endpoint
2. **Return an appropriate error response** (typically 400 Bad Request)

:::tip
Configure custom error responses for blocked headers in your [app configuration](../../../revali/app-configuration/default-responses.md).
:::

## Best Practices

### Block at the Right Level

```dart
// ✅ Good - Block sensitive headers globally
@PreventHeaders({'X-Secret-Key'})
@App()
class MyApp {
  // All endpoints block X-Secret-Key
}

// ✅ Good - Block specific headers per controller
@PreventHeaders({'X-Debug-Info'})
@Controller('debug')
class DebugController {
  // Only debug endpoints block X-Debug-Info
}
```
