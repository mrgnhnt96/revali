---
title: Headers
description: Set HTTP headers to send additional information to the client
---

# Response Headers

> Access via: `context.response.headers`

HTTP headers provide additional information about the response. Revali automatically sets many headers for you, but you can customize them as needed.

## Automatic Headers

Revali automatically sets these headers based on your response:

### Content-Type

- **JSON objects/arrays**: `application/json`
- **Strings**: `text/plain`
- **Files**: Based on file extension
- **Streams**: `application/octet-stream`

### Content-Length

- Automatically calculated for most response types
- Set manually only when needed

### Other Headers

- **Date**: Current timestamp
- **Server**: Revali server information
- **Transfer-Encoding**: For streaming responses

## Setting Headers

### Via Annotations (Recommended)

Set headers statically using annotations:

```dart
@Controller('api')
class ApiController {
  @Get('data')
  @SetHeader('Cache-Control', 'max-age=3600')
  @SetHeader('X-Custom-Header', 'value')
  String getData() {
    return 'Cached data';
  }
}
```

### Via Lifecycle Components

Set headers dynamically in middleware, guards, or interceptors:

```dart
class SecurityHeaders implements LifecycleComponent {
  MiddlewareResult processRequest(Response response) {
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('X-Frame-Options', 'DENY');
    response.headers.set('X-XSS-Protection', '1; mode=block');

    return const MiddlewareResult.next();
  }
}
```

### Via Binding

Access headers directly in endpoint methods:

```dart
@Controller('api')
class ApiController {
  @Get('data')
  String getData(ResponseHeaders headers) {
    headers.set('Cache-Control', 'no-cache');
    headers.set('X-Response-Time', DateTime.now().toIso8601String());

    return 'Data';
  }
}
```

## Common Headers

### Caching

```dart
// Cache for 1 hour
@SetHeader('Cache-Control', 'max-age=3600')

// No cache
@SetHeader('Cache-Control', 'no-cache, no-store, must-revalidate')

// Cache with validation
@SetHeader('Cache-Control', 'max-age=3600, must-revalidate')
@SetHeader('ETag', '"abc123"')
```

### CORS

These are automatically handled by revali's [allow origins](../access-control/allow-origins.md) feature.

```dart
@SetHeader('Access-Control-Allow-Origin', '*')
@SetHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE')
@SetHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization')
```

### Security

```dart
@SetHeader('X-Content-Type-Options', 'nosniff')
@SetHeader('X-Frame-Options', 'DENY')
@SetHeader('X-XSS-Protection', '1; mode=block')
@SetHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
```

### Content Type

These are automatically handled by revali's [body](./body.md) feature.

```dart
// Override automatic content type
@SetHeader('Content-Type', 'application/xml')

// For file downloads
@SetHeader('Content-Disposition', 'attachment; filename="file.pdf"')
```

## File Headers

When returning files, Revali automatically sets appropriate headers:

```dart
@Controller('files')
class FileController {
  @Get('download')
  File downloadFile(Headers headers) {
    return File('path/to/document.pdf');
  }
}
```

**Automatic headers for files:**

- `Content-Type`: Based on file extension
- `Content-Disposition`: `attachment; filename="my-document.pdf"`
- `Content-Length`: File size

## Best Practices

### Use Annotations for Static Headers

```dart
// ✅ Good - Clear and static
@Get('data')
@SetHeader('Cache-Control', 'max-age=3600')
String getData() {
  return 'Data';
}

// ❌ Avoid - Unnecessary complexity for static values
@Get('data')
String getData(Headers headers) {
  headers.set('Cache-Control', 'max-age=3600');
  return 'Data';
}
```

### Use Lifecycle Components for Dynamic Headers

```dart
// ✅ Good - Dynamic based on conditions
class SecurityHeaders implements LifecycleComponent {
  MiddlewareResult processRequest(Response response) {
    response.headers.set('X-Content-Type-Options', 'nosniff');
    return const MiddlewareResult.next();
  }
}
```

### Avoid Magic Strings

```dart
// ✅ Good - Use constants
import 'dart:io';

@SetHeader(HttpHeaders.cacheControlHeader, 'max-age=3600')

// ❌ Avoid - Magic strings
@SetHeader('Cache-Control', 'max-age=3600')
```

## What's Next?

- Learn about [response body](./body.md) for setting response data
- Explore [status codes](./status-code.md) for HTTP status codes
- See [cookies](./cookies.md) for session management
- Check out [WebSockets](./websockets.md) for real-time communication
