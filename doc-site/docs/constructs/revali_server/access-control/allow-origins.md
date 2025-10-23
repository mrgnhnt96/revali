---
description: Control which origins can access your API resources
sidebar_position: 0
---

# Allow Origins

Allow Origins is a CORS (Cross-Origin Resource Sharing) security mechanism that controls which domains can access your API resources. It helps protect your API by only allowing requests from trusted origins.

## What Are Allow Origins?

Allow Origins specify which domains (origins) are permitted to make requests to your API. This is essential for web security because browsers block cross-origin requests by default to prevent malicious websites from accessing sensitive data.

### Why Are Allow Origins Important?

Allow Origins provide security by:

- **Preventing unauthorized access** - Only trusted domains can access your API
- **Protecting against CSRF attacks** - Malicious sites can't make requests on behalf of users
- **Controlling resource sharing** - You decide which applications can use your API
- **Enforcing same-origin policy** - Browsers respect your origin restrictions

### How Allow Origins Work

When a browser makes a cross-origin request, it checks if the origin is allowed. If not, the browser blocks the request before it reaches your server.

:::info
**Default Behavior:** By default, Revali allows all origins to access your API. You only need to configure `@AllowOrigins` when you want to restrict access to specific domains.

**Recommendation:** We recommend explicitly configuring `@AllowOrigins` with specific domains for better security, even if you want to allow multiple origins.
:::

## Using Allow Origins

### Basic Usage

Use the `@AllowOrigins` annotation to specify allowed domains:

```dart
import 'package:revali_router/revali_router.dart';

@AllowOrigins({'https://myapp.com', 'https://admin.myapp.com'})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data for allowed origins';
  }
}
```

### Scoping

Allow Origins can be applied at different levels:

- **App level** - Applies to all controllers and endpoints
- **Controller level** - Applies to all endpoints in the controller
- **Endpoint level** - Applies only to specific endpoints

```dart
@AllowOrigins({'https://myapp.com'})
@App()
class MyApp {
  // All controllers allow https://myapp.com
}

@AllowOrigins({'https://admin.myapp.com'})
@Controller('admin')
class AdminController {
  // Allows both https://myapp.com (inherited) and https://admin.myapp.com (local)

  @AllowOrigins({'https://internal.myapp.com'})
  @Get('sensitive')
  String getSensitive() {
    // Allows https://myapp.com, https://admin.myapp.com, and https://internal.myapp.com
  }
}
```

:::tip
Learn more about [scoping in lifecycle components](../lifecycle-components/overview.md#scoping).
:::

### Wildcard Origins

Use `@AllowOrigins.all()` to allow any origin (use with caution):

```dart
@AllowOrigins.all()
@Controller('public')
class PublicController {
  @Get('data')
  String getData() {
    return 'Public data accessible from any origin';
  }
}
```

:::caution
Using wildcard origins (`*`) allows any website to access your API. Only use this for truly public APIs that don't handle sensitive data.
:::

### Inheritance

By default, `@AllowOrigins` is inherited by child controllers and endpoints. This means that origins allowed at the app level will also be allowed in all controllers and endpoints within that app.

```dart
@AllowOrigins({'https://myapp.com'})
@Controller('api')
class ApiController {
  @Get('public')
  String getPublic() {
    // This endpoint allows https://myapp.com (inherited)
    return 'Public data';
  }
}
```

### Disabling Inheritance

Use `@AllowOrigins.noInherit()` to prevent inheritance of parent-level allowed origins:

```dart
@AllowOrigins({'https://myapp.com'})
@Controller('api')
class ApiController {
  @AllowOrigins.noInherit({'https://admin.myapp.com'})
  @Get('admin')
  String getAdmin() {
    // This endpoint only allows https://admin.myapp.com
    // https://myapp.com is NOT allowed (inheritance disabled)
    return 'Admin data';
  }
}
```

### Combining Origins

You can combine inherited and local allowed origins:

```dart
@AllowOrigins({'https://myapp.com'})
@Controller('api')
class ApiController {
  @AllowOrigins({'https://admin.myapp.com'})
  @Get('protected')
  String getProtected() {
    // This endpoint allows both https://myapp.com (inherited) and https://admin.myapp.com (local)
    return 'Protected data';
  }
}
```

## Common Use Cases

### Single Domain API

```dart
@AllowOrigins({'https://myapp.com'})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data for myapp.com only';
  }
}
```

### Multi-Domain API

```dart
@AllowOrigins({
  'https://myapp.com',
  'https://admin.myapp.com',
  'https://mobile.myapp.com'
})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data for multiple domains';
  }
}
```

### Environment-Specific Origins

```dart
@AllowOrigins({
  'https://myapp.com',           // Production
  'https://staging.myapp.com',   // Staging
  'http://localhost:3000'        // Development
})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data for all environments';
  }
}
```

### Public API

```dart
@AllowOrigins.all()
@Controller('public')
class PublicController {
  @Get('status')
  String getStatus() {
    return 'Public API status';
  }
}
```

## Error Handling

When a client sends a request from a disallowed origin, the browser will:

1. **Block the request** before it reaches your server
2. **Show a CORS error** in the browser console
3. **Prevent the response** from being processed by the client

:::tip
Configure custom error responses for CORS failures in your [app configuration](../../../revali/app-configuration/default-responses.md).
:::

## Best Practices

### Use Specific Origins

```dart
// ✅ Good - Specific origins
@AllowOrigins({'https://myapp.com', 'https://admin.myapp.com'})

// ❌ Avoid - Too permissive
@AllowOrigins.all()
```

### Include All Environments

```dart
@AllowOrigins({
  'https://myapp.com',           // Production
  'https://staging.myapp.com',   // Staging
  'http://localhost:3000',       // Development
  'http://localhost:8080'        // Local development
})
@Controller('api')
class ApiController {
  // Controller implementation
}
```

### Document Origin Requirements

```dart
/// Allows access from production and staging environments
@AllowOrigins({
  'https://myapp.com',           // Production domain
  'https://staging.myapp.com'    // Staging domain
})
@Controller('api')
class ApiController {
  // Controller implementation
}
```

### Use HTTPS in Production

```dart
// ✅ Good - Secure origins
@AllowOrigins({'https://myapp.com'})

// ❌ Avoid - Insecure origins in production
@AllowOrigins({'http://myapp.com'})
```

## Related Topics

- **[Expect Headers](./expect-headers.md)** - Require specific headers in requests
- **[Prevent Headers](./prevent-headers.md)** - Block specific headers from requests
- **[Lifecycle Components](../lifecycle-components/overview.md)** - Learn about scoping and inheritance
