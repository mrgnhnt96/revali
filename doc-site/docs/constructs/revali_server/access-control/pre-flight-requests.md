---
description: Handle OPTIONS and HEAD requests for CORS pre-flight checks
---

# Pre-flight Requests

Pre-flight requests are automatic HTTP requests sent by browsers before certain cross-origin requests to check if the actual request is allowed. Revali automatically handles these requests and applies your access control settings.

## What Are Pre-flight Requests?

Pre-flight requests are sent by browsers when:

- **OPTIONS requests** - Sent before "complex" requests (POST, PUT, DELETE with custom headers)
- **HEAD requests** - Sent to check if a resource exists without downloading it

These requests help browsers determine if the actual request will be allowed by the server before sending it.

## Automatic Handling

Revali automatically handles pre-flight requests and applies your access control settings:

### CORS Headers

When a pre-flight request is received, Revali automatically sets the appropriate CORS headers:

```dart
// Automatic headers set by Revali
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
```

### Origin Validation

The origin is validated against your `@AllowOrigins` settings:

```dart
@AllowOrigins({'https://example.com', 'https://app.example.com'})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data';
  }
}
```

**Pre-flight request from `https://example.com`:**

- ✅ **Allowed** - Origin matches allowed list
- Response includes CORS headers

**Pre-flight request from `https://malicious.com`:**

- ❌ **Blocked** - Origin not in allowed list
- Returns 403 Forbidden

## Access Control Integration

### With Expected Headers

```dart
@ExpectHeaders({'Authorization', 'X-API-Key'})
@Controller('api')
class ApiController {
  @Post('data')
  String createData(@Body() Map<String, dynamic> data) {
    return 'Created';
  }
}
```

**Pre-flight behavior:**

- ✅ Request includes required headers - Allowed
- ❌ Request missing required headers - Blocked

### With Prevented Headers

```dart
@PreventHeaders({'X-Malicious-Header'})
@Controller('api')
class ApiController {
  @Get('data')
  String getData() {
    return 'Data';
  }
}
```

**Pre-flight behavior:**

- ✅ Request without blocked headers - Allowed
- ❌ Request with blocked headers - Blocked

## Testing Pre-flight Requests

### Using curl

```bash
# Test OPTIONS request
curl -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  http://localhost:8080/api/data

# Test HEAD request
curl -X HEAD \
  -H "Origin: https://example.com" \
  http://localhost:8080/api/data
```

### Expected Response

**Successful pre-flight response:**

```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE (or the methods allowed by your API)
Access-Control-Allow-Headers: Content-Type, Authorization (or the headers allowed by your API)
Access-Control-Allow-Credentials: true
```

**Failed pre-flight response:**

```http
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "error": "Origin is not allowed."
}
```

## Common Patterns

### API with Authentication

```dart
@AllowOrigins({'https://myapp.com'})
@ExpectHeaders({'Authorization'})
@Controller('api')
class ApiController {
  @Post('users')
  User createUser(@Body() CreateUserRequest request) {
    return userService.createUser(request);
  }
}
```

### Public API

```dart
@AllowOrigins.all()
@Controller('public')
class PublicController {
  @Get('status')
  Map<String, String> getStatus() {
    return {'status': 'online'};
  }
}
```

## Best Practices

### Use Specific Origins

```dart
// ✅ Good - Specific origins
@AllowOrigins({'https://myapp.com', 'https://admin.myapp.com'})

// ❌ Avoid - Too permissive
@AllowOrigins.all()
```

### Combine with Other Access Controls

```dart
// ✅ Good - Comprehensive access control
@AllowOrigins({'https://myapp.com'})
@ExpectHeaders({'Authorization'})
@PreventHeaders({'X-Malicious-Header'})
@Controller('api')
class SecureController {
  // Endpoints
}
```

## Troubleshooting

### Common Issues

**Pre-flight request fails:**

- Check if origin is in `@AllowOrigins` list
- Verify required headers are present
- Ensure no blocked headers are included

**CORS headers not set:**

- Verify access control annotations are properly configured
- Check if pre-flight request is being handled correctly

**Browser still blocks requests:**

- Ensure all required CORS headers are present
- Check if credentials are properly configured
- Verify origin matching is working correctly

## What's Next?

- Learn about [allow origins](./allow-origins.md) for CORS configuration
- Explore [expected headers](./expect-headers.md) for required headers
- See [prevented headers](./prevent-headers.md) for blocked headers
