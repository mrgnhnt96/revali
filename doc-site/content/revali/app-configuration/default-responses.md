---
title: Default Responses
description: Customize the default responses returned by the server
---

Default responses are the standardized responses that Revali returns during specific events in the request lifecycle. These responses provide consistent error handling and user experience across your application.

## What are Default Responses?

Default responses handle common scenarios that occur during request processing:

- **Error Handling**: Standardized error responses for different failure scenarios
- **User Experience**: Consistent messaging across your API
- **Security**: Controlled information disclosure in error responses
- **Debugging**: Appropriate detail levels for different environments

## Configuring Default Responses

Override the `defaultResponses` getter in your `AppConfig` class:

<CodeFile name="routes/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  DefaultResponses get defaultResponses => DefaultResponses(
    internalServerError: SimpleResponse(
      statusCode: 500,
      body: 'An unexpected error occurred. Please try again later.',
    ),
    notFound: SimpleResponse(
      statusCode: 404,
      body: 'The requested resource was not found.',
    ),
    failedCorsOrigin: SimpleResponse(
      statusCode: 403,
      body: 'Access denied: Origin not allowed.',
    ),
    failedCorsHeaders: SimpleResponse(
      statusCode: 403,
      body: 'Access denied: Headers not allowed.',
    ),
  );
}
```

</CodeFile>

## Response Types

### Internal Server Error (500)

Returned when an unhandled exception occurs:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  @override
  DefaultResponses get defaultResponses => DefaultResponses(
    internalServerError: SimpleResponse(
      statusCode: 500,
      body: 'Something went wrong on our end. We\'re working to fix it!',
    ),
  );
}
```

</CodeFile>

**Default Response:**

```dart
SimpleResponse(
  statusCode: 500,
  body: 'Internal Server Error',
)
```

### Not Found (404)

Returned when no route matches the request:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  @override
  DefaultResponses get defaultResponses => DefaultResponses(
    notFound: SimpleResponse(
      statusCode: 404,
      body: 'The page you\'re looking for doesn\'t exist.',
    ),
  );
}
```

</CodeFile>

**Default Response:**

```dart
SimpleResponse(
  statusCode: 404,
  body: 'Not Found',
)
```

### CORS Origin Failure (403)

Returned when a request comes from an unauthorized origin:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  @override
  DefaultResponses get defaultResponses => DefaultResponses(
    failedCorsOrigin: SimpleResponse(
      statusCode: 403,
      body: 'Access denied: Your origin is not authorized to access this resource.',
    ),
  );
}
```

</CodeFile>

**Default Response:**

```dart
SimpleResponse(
  statusCode: 403,
  body: 'CORS policy does not allow access from this origin.',
)
```

### CORS Headers Failure (403)

Returned when a request contains unauthorized headers:

<CodeFile name="routes/main_app.dart">

```dart
@App()
final class MainApp extends AppConfig {
  @override
  DefaultResponses get defaultResponses => DefaultResponses(
    failedCorsHeaders: SimpleResponse(
      statusCode: 403,
      body: 'Access denied: The request contains unauthorized headers.',
    ),
  );
}
```

</CodeFile>

**Default Response:**

```dart
SimpleResponse(
  statusCode: 403,
  body: 'CORS policy does not allow access with these headers.',
)
```

## Response Best Practices

### 🎯 **User Experience**

- **Clear Messages**: Use clear, actionable error messages
- **Consistent Format**: Maintain consistent response structure
- **Appropriate Detail**: Provide appropriate detail for the environment
- **Helpful Guidance**: Include guidance on how to resolve issues

### 🔒 **Security**

- **Information Disclosure**: Avoid exposing sensitive information in error responses
- **Error Details**: Limit error details in production environments
- **Logging**: Log detailed errors server-side for debugging

### 🌐 **API Design**

- **HTTP Status Codes**: Use appropriate HTTP status codes
- **Response Format**: Maintain consistent response format across all endpoints
- **Error Codes**: Include error codes for programmatic handling

### 🛠️ **Development**

- **Debug Information**: Include helpful debug information in development
- **Request Tracking**: Include request IDs for tracking
- **Environment Awareness**: Adapt responses based on environment

## Common Response Patterns

### Standard API Error Format

```dart
SimpleResponse(
  statusCode: 500,
  body: {
    'success': false,
    'error': {
      'code': 'INTERNAL_SERVER_ERROR',
      'message': 'An unexpected error occurred',
      'details': isDevelopment ? exception.toString() : null,
    },
    'timestamp': DateTime.now().toIso8601String(),
    'requestId': requestId,
  },
)
```

### Validation Error Format

```dart
SimpleResponse(
  statusCode: 400,
  body: {
    'success': false,
    'error': {
      'code': 'VALIDATION_ERROR',
      'message': 'Request validation failed',
      'details': validationErrors,
    },
    'timestamp': DateTime.now().toIso8601String(),
  },
)
```

### Rate Limiting Error Format

```dart
SimpleResponse(
  statusCode: 429,
  body: {
    'success': false,
    'error': {
      'code': 'RATE_LIMIT_EXCEEDED',
      'message': 'Too many requests. Please try again later.',
      'retryAfter': retryAfterSeconds,
    },
    'timestamp': DateTime.now().toIso8601String(),
  },
)
```

## Next Steps

- **[Environment Variables](/revali/app-configuration/env-vars)**: Learn about environment variable configuration
- **[Flavors](/revali/app-configuration/flavors)**: Create environment-specific configurations
- **[Error Handling](/constructs/revali_server/lifecycle-components/advanced/exception-catchers)**: Advanced error handling techniques
