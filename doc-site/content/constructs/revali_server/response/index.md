---
title: Overview
description: Control the outgoing HTTP response
---

> Access via: `context.response`

The `Response` object represents the outgoing HTTP response. It contains all the information about the response, including headers, body, status code, and cookies. You can access and modify the response through the context in lifecycle components.

## Key Properties

- **`body`** - The response payload (data sent to client)
- **`headers`** - HTTP headers sent with the response
- **`statusCode`** - HTTP status code (200, 404, 500, etc.)

## Accessing the Response

### Via Binding

Access the response from the context in lifecycle components by using the `Response` parameter.

```dart
class MyMiddleware implements LifecycleComponent {
  MiddlewareResult processRequest(Response response) {
    response.statusCode = 200;
    response.headers.set('Cache-Control', 'no-cache');

    return const MiddlewareResult.next();
  }
}
```

You can also access response properties directly in endpoint methods:

```dart
@Controller('api')
class ApiController {
  @Get('data')
  String getData(Headers headers) {
    headers.set('X-Custom-Header', 'value');

    return 'Data';
  }
}
```

<Callout type="warning">

**Avoid using `Response` in endpoint methods.** Instead, use specific types like `Headers` or access the response through lifecycle components. This keeps your endpoints clean and focused.

</Callout>

## Common Patterns

### Setting Response Data

```dart
// Return data from endpoint (recommended)
@Get('users')
List<User> getUsers() {
  return userService.getAllUsers();
}

// Set data in lifecycle component
class ResponseProcessor implements LifecycleComponent {
  InterceptorPostResult processResponse(Response response) {
    response.body['timestamp'] = DateTime.now().toIso8601String();
  }
}
```

### Setting Headers

```dart
// Via annotation
@Get('data')
@SetHeader('Cache-Control', 'max-age=3600')
String getData() {
  return 'Cached data';
}

// Via lifecycle component
class SecurityHeaders implements LifecycleComponent {
  MiddlewareResult processRequest(Response response) {
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('X-Frame-Options', 'DENY');

    return const MiddlewareResult.next();
  }
}
```

### Setting Status Codes

```dart
// Via annotation
@Post('job')
@StatusCode(201)
void startJob() {
   service.startAsyncOperation();
}

// Via interceptor (post)
class StatusCodeProcessor implements LifecycleComponent {
  InterceptorPostResult processResponse(Response response) {
    if (response.body.data == null) {
      response.statusCode = 201;
    }
  }
}
```

## What's Next?

- Learn about [response body](/constructs/revali_server/response/body) for setting response data
- Explore [response headers](/constructs/revali_server/response/headers) for HTTP headers
- See [status codes](/constructs/revali_server/response/status-code) for HTTP status codes
- Check out [cookies](/constructs/revali_server/response/cookies) for session management
- Discover [WebSockets](/constructs/revali_server/response/websockets) for real-time communication
- Learn about [Server-Sent Events](/constructs/revali_server/response/server-sent-events) for streaming updates
