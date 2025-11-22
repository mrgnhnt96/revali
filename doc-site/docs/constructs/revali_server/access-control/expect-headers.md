---
description: Require specific headers to be present in requests
---

# Expect Headers

Expect Headers is a security mechanism that requires specific headers to be present in HTTP requests. Unlike [Prevent Headers](./prevent-headers.md) that block headers, Expect Headers ensures that certain headers are mandatory for requests to be processed.

## What Are Expect Headers?

Expect Headers enforce that clients include specific headers in their requests. This is useful for:

- **API authentication** - Requiring `Authorization` headers
- **Client identification** - Requiring `X-Client-ID` headers
- **API versioning** - Requiring `X-API-Version` headers
- **Security validation** - Requiring custom security headers

### How Expect Headers Work

When a client sends a request without the required headers, the server will reject the request before it reaches your endpoint logic. This provides early validation and security.

## Using Expect Headers

### Basic Usage

Use the `@ExpectHeaders` annotation to require specific headers:

```dart
import 'package:revali_router/revali_router.dart';

@ExpectHeaders({'Authorization', 'X-Client-ID'})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data for authenticated clients';
  }
}
```

### Scoping

Expect Headers can be applied at different levels:

- **App level** - Applies to all controllers and endpoints
- **Controller level** - Applies to all endpoints in the controller
- **Endpoint level** - Applies only to specific endpoints

```dart
@ExpectHeaders({'X-API-Version'})
@App()
class MyApp {
  // All controllers require X-API-Version
}

@ExpectHeaders({'Authorization'})
@Controller('users')
class UsersController {
  // Requires both X-API-Version (inherited) and Authorization

  @ExpectHeaders({'X-Client-ID'})
  @Get('profile')
  String getProfile() {
    // Requires X-API-Version, Authorization, and X-Client-ID
  }
}
```

:::tip
Learn more about [scoping in lifecycle components](../lifecycle-components/overview.md#scoping).
:::

### Inheritance

By default, `@ExpectHeaders` is inherited by child controllers and endpoints. This means that headers required at the app level will also be required in all controllers and endpoints within that app.

```dart
@ExpectHeaders({'X-API-Version'})
@Controller('api')
class ApiController {
  @Get('public')
  String getPublic() {
    // This endpoint requires X-API-Version (inherited)
    return 'Public data';
  }
}
```

### Disabling Inheritance

Use `@ExpectHeaders.noInherit()` to prevent inheritance of parent-level required headers:

```dart
@ExpectHeaders({'X-API-Version'})
@Controller('api')
class ApiController {
  @ExpectHeaders.noInherit({'X-Client-ID'})
  @Get('internal')
  String getInternal() {
    // This endpoint only requires X-Client-ID
    // X-API-Version is NOT required (inheritance disabled)
    return 'Internal data';
  }
}
```

### Combining Headers

You can combine inherited and local required headers:

```dart
@ExpectHeaders({'X-API-Version'})
@Controller('api')
class ApiController {
  @ExpectHeaders({'Authorization'})
  @Get('protected')
  String getProtected() {
    // This endpoint requires both X-API-Version (inherited) and Authorization (local)
    return 'Protected data';
  }
}
```

## Common Use Cases

### API Authentication

```dart
@ExpectHeaders({'Authorization'})
@Controller('api')
class ApiController {
  @Get('user-data')
  String getUserData() {
    return 'User data for authenticated clients';
  }
}
```

### Client Identification

```dart
@ExpectHeaders({'X-Client-ID', 'X-Client-Version'})
@Controller('api')
class ApiController {
  @Get('analytics')
  String getAnalytics() {
    return 'Analytics data for identified clients';
  }
}
```

### API Versioning

```dart
@ExpectHeaders({'X-API-Version'})
@Controller('v2')
class V2Controller {
  @Get('data')
  String getData() {
    return 'V2 API response';
  }
}
```

### Security Headers

```dart
@ExpectHeaders({'X-CSRF-Token', 'X-Request-ID'})
@Controller('admin')
class AdminController {
  @Post('sensitive-action')
  String performAction() {
    return 'Action completed with security validation';
  }
}
```

## Error Handling

When a client sends a request without required headers, the server will:

1. **Reject the request** before it reaches your endpoint
2. **Return an appropriate error response** (typically 400 Bad Request)
3. **Include details** about which headers are missing

:::tip
Configure custom error responses for missing headers in your [app configuration](../../../revali/app-configuration/default-responses.md).
:::

## Best Practices

### Use Clear Header Names

```dart
// ✅ Good - Clear purpose
@ExpectHeaders({'Authorization', 'X-API-Version'})

// ❌ Avoid - Unclear purpose
@ExpectHeaders({'H1', 'H2'})
```

### Require at the Right Level

```dart
// ✅ Good - Require authentication globally
@ExpectHeaders({'Authorization'})
@App()
class MyApp {
  // All endpoints require authentication
}

// ✅ Good - Require specific headers per controller
@ExpectHeaders({'X-Client-ID'})
@Controller('analytics')
class AnalyticsController {
  // Only analytics endpoints require client ID
}
```

### Document Required Headers

```dart
/// Requires authentication and API version headers
@ExpectHeaders({
  'Authorization',    // Bearer token for authentication
  'X-API-Version'     // API version for compatibility
})
@Controller('api')
class ApiController {
  // Controller implementation
}
```

## Related Topics

- **[Prevent Headers](./prevent-headers.md)** - Block specific headers from requests
- **[Allow Origins](./allow-origins.md)** - Control which origins can access your API
- **[Lifecycle Components](../lifecycle-components/overview.md)** - Learn about scoping and inheritance
