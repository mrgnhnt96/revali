---
title: Cookies
description: Manage cookies for session data and user preferences
---

# Response Cookies

> Access via: `context.response.headers.setCookies` and `context.request.headers.cookies`

Cookies are small pieces of data stored on the client side and sent with each request. They're commonly used for session management, user preferences, and tracking.

## Setting Cookies

### Via Lifecycle Components (Recommended)

Set cookies in middleware, guards, or interceptors:

```dart
class AuthMiddleware implements LifecycleComponent {
  MiddlewareResult processRequest(Request request, Response response) {
    // Check for existing session cookie
    final sessionId = request.headers.cookies['sessionId'];

    if (sessionId == null) {
      // Create new session
      final newSessionId = generateSessionId();
      response.headers.setCookies['sessionId'] = newSessionId;
      response.headers.setCookies.expires = DateTime.now().add(const Duration(days: 7));
    }

    return const MiddlewareResult.next();
  }
}
```

### Via Binding

Access cookies directly in endpoint methods:

```dart
@Controller('api')
class ApiController {
  @Get('profile')
  User getProfile(
    @Cookie() String? sessionId,
    SetCookies setCookies,
  ) {
    if (sessionId == null) {
      // Set new session cookie
      setCookies['sessionId'] = generateSessionId();
      setCookies.expires = DateTime.now().add(const Duration(days: 7));
    }

    return userService.getUserBySession(sessionId);
  }
}
```

## Reading Cookies

### Via Lifecycle Components

```dart
class AuthGuard implements LifecycleComponent {
  GuardResult protect(Context context) {
    final sessionId = context.request.headers.cookies['sessionId'];

    if (sessionId == null || !isValidSession(sessionId)) {
      return const GuardResult.block(
        status: 401,
        message: 'Authentication required',
      );
    }

    return const GuardResult.pass();
  }
}
```

### Via Binding

```dart
@Controller('api')
class ApiController {
  @Get('data')
  String getData(@Cookie() String? sessionId) {
    if (sessionId == null) {
      throw HttpException(
        statusCode: 401,
        body: {'error': 'Authentication required'},
      );
    }

    return 'Protected data';
  }
}
```

## Cookie Properties

### Basic Cookie

```dart
response.headers.setCookies['sessionId'] = 'abc123';
```

### Cookie with Expiration

```dart
response.headers.setCookies['sessionId'] = 'abc123';
response.headers.setCookies.expires = DateTime.now().add(const Duration(days: 7));
```

### Secure Cookie

```dart
response.headers.setCookies['sessionId'] = 'abc123';
response.headers.setCookies.secure = true;
response.headers.setCookies.httpOnly = true;
```

### Domain and Path

```dart
response.headers.setCookies['sessionId'] = 'abc123';
response.headers.setCookies.domain = '.example.com';
response.headers.setCookies.path = '/api';
```

## Common Cookie Patterns

### Session Management

```dart
class SessionManager implements LifecycleComponent {
  MiddlewareResult processRequest(Request request, Response response) {
    final sessionId = request.headers.cookies['sessionId'];

    if (sessionId == null) {
      // Create new session
      final newSessionId = generateSessionId();
      response.headers.setCookies['sessionId'] = newSessionId;
      response.headers.setCookies.expires = DateTime.now().add(const Duration(days: 7));
      response.headers.setCookies.httpOnly = true;
      response.headers.setCookies.secure = true;
    } else {
      // Validate existing session
      if (!isValidSession(sessionId)) {
        // Clear invalid session
        response.headers.setCookies['sessionId'] = '';
        response.headers.setCookies.expires = DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return const MiddlewareResult.next();
  }
}
```

### User Preferences

```dart
@Controller('api')
class PreferencesController {
  @Post('theme')
  void setTheme(
    @Body() String theme,
    SetCookies setCookies,
  ) {
    setCookies['theme'] = theme;
    setCookies.expires = DateTime.now().add(const Duration(days: 365));
  }

  @Get('theme')
  String getTheme(@Cookie() String? theme) {
    return theme ?? 'light';
  }
}
```

### CSRF Protection

```dart
class CSRFProtection implements LifecycleComponent {
  MiddlewareResult processRequest(SetCookies setCookies) {
    // Generate CSRF token
    final csrfToken = generateCSRFToken();
    setCookies['csrfToken'] = csrfToken;
    setCookies.httpOnly = true;
    setCookies.secure = true;

    return const MiddlewareResult.next();
  }
}
```

## Cookie Security

### Secure Cookies

```dart
// Only send over HTTPS
response.headers.setCookies.secure = true;

// Prevent JavaScript access
response.headers.setCookies.httpOnly = true;

// Restrict to same site
response.headers.setCookies.sameSite = 'Strict';
```

### Cookie Expiration

```dart
// Session cookie (expires when browser closes)
response.headers.setCookies['sessionId'] = 'abc123';

// Persistent cookie (expires after 7 days)
response.headers.setCookies['sessionId'] = 'abc123';
response.headers.setCookies.expires = DateTime.now().add(const Duration(days: 7));

// Clear cookie (expires in the past)
response.headers.setCookies['sessionId'] = '';
response.headers.setCookies.expires = DateTime.fromMillisecondsSinceEpoch(0);
```

## Reading All Cookies

### Via Lifecycle Components

```dart
class CookieLogger implements LifecycleComponent {
  MiddlewareResult processRequest(Request request, Response response) {
    final cookies = request.headers.cookies;

    for (final entry in cookies.entries) {
      print('Cookie: ${entry.key} = ${entry.value}');
    }

    return const MiddlewareResult.next();
  }
}
```

### Via Binding

```dart
@Controller('api')
class ApiController {
  @Get('cookies')
  Map<String, String> getAllCookies(Cookies cookies) {
    return Map.from(cookies);
  }
}
```

## What's Next?

- Learn about [response body](./body.md) for setting response data
- Explore [response headers](./headers.md) for HTTP headers
- See [status codes](./status-code.md) for HTTP status codes
- Check out [WebSockets](./websockets.md) for real-time communication
