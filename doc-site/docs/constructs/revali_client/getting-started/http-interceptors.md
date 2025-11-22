---
title: Interceptors
description: Intercept HTTP requests and responses
sidebar_position: 3
---

# HTTP Interceptors

HTTP Interceptors provide a powerful way to observe and modify HTTP requests and responses globally across your Revali Client. They enable cross-cutting concerns like authentication, logging, error handling, and request/response transformation.

## Overview

Interceptors run at two key points in the HTTP lifecycle:

1. **Before Request** - Modify outgoing requests (add headers, log, etc.)
2. **After Response** - Process incoming responses (handle errors, parse data, etc.)

**Common use cases:**

- Adding authentication headers
- Logging requests and responses
- Error handling and retry logic
- Request/response transformation
- Performance monitoring
- Cache management

---

## The HttpInterceptor Interface

Every interceptor implements the `HttpInterceptor` interface:

```dart
abstract interface class HttpInterceptor {
  /// Called before each request is sent
  FutureOr<void> onRequest(HttpRequest request);

  /// Called after each response is received
  FutureOr<void> onResponse(HttpResponse response);
}
```

### Method Details

#### `onRequest`

Called before the HTTP request is sent to the server.

**Parameters:**

- `request` - The `HttpRequest` object you can inspect and modify

**Common uses:**

- Add or modify headers
- Log request details
- Validate request data
- Add authentication tokens

**Return type:** `FutureOr<void>` - Can be synchronous or asynchronous

#### `onResponse`

Called after the HTTP response is received from the server.

**Parameters:**

- `response` - The `HttpResponse` object you can inspect and modify

**Common uses:**

- Log response details
- Handle authentication errors
- Transform response data
- Trigger side effects

**Return type:** `FutureOr<void>` - Can be synchronous or asynchronous

---

## Creating an Interceptor

### Basic Interceptor

A simple logging interceptor:

```dart
import 'dart:async';
import 'package:revali_client/revali_client.dart';

class LoggingInterceptor implements HttpInterceptor {
  const LoggingInterceptor();

  @override
  FutureOr<void> onRequest(HttpRequest request) {
    print('→ ${request.method} ${request.url}');
    print('  Headers: ${request.headers}');
    if (request.body.isNotEmpty) {
      print('  Body: ${request.body}');
    }
  }

  @override
  FutureOr<void> onResponse(HttpResponse response) {
    print('← ${response.statusCode} ${response.reasonPhrase}');
    print('  Headers: ${response.headers}');
  }
}
```

### Authentication Interceptor

Add authentication headers to every request:

```dart
class AuthInterceptor implements HttpInterceptor {
  const AuthInterceptor(this.storage);

  final Storage storage;

  @override
  Future<void> onRequest(HttpRequest request) async {
    // Get token from storage
    if (await storage['auth_token'] case final String token) {
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  @override
  Future<void> onResponse(HttpResponse response) async {
    // Handle unauthorized responses
    if (response.statusCode == 401) {
      // Clear auth token on unauthorized
      await storage.remove('auth_token');
      print('Session expired - please log in again');
    }
  }
}
```

### Error Handling Interceptor

Centralized error handling:

```dart
class ErrorInterceptor implements HttpInterceptor {
  const ErrorInterceptor();

  @override
  void onRequest(HttpRequest request) {
    // No action needed before request
  }

  @override
  void onResponse(HttpResponse response) {
    if (response.statusCode >= 400) {
      // Log errors
      print('Error ${response.statusCode}: ${response.reasonPhrase}');

      // You could also show notifications, send to error tracking, etc.
      switch (response.statusCode) {
        case 400:
          print('Bad Request - Check your input');
        case 403:
          print('Forbidden - You don\'t have permission');
        case 404:
          print('Not Found - Resource doesn\'t exist');
        case 500:
          print('Server Error - Please try again later');
      }
    }
  }
}
```

---

## Registering Interceptors

Interceptors are registered when creating the `Server` instance by passing a custom `HttpClient`:

```dart
import 'package:revali_client/revali_client.dart';

void main() async {
  // Create storage
  final storage = SessionStorage();

  // Create HTTP client with interceptors
  final httpClient = HttpPackageClient(
    interceptors: [
      LoggingInterceptor(),
      AuthInterceptor(storage),
      ErrorInterceptor(),
    ],
  );

  // Create server with custom client
  final server = Server(
    client: httpClient,
    storage: storage,
  );

  // All requests will now go through the interceptors
  await server.users.getAll();
}
```

If you're not using a custom `HttpClient`, you can register the interceptors on the client instance.

```dart
final storage = SessionStorage();
final server = Server(storage: storage);

server.client.interceptors.addAll([
  LoggingInterceptor(),
  AuthInterceptor(storage),
  ErrorInterceptor(),
]);
```

### Interceptor Order

Interceptors run in the order they're registered:

```dart
final httpClient = HttpPackageClient(
  interceptors: [
    LoggingInterceptor(),     // Runs 1st for requests, 3rd for responses
    AuthInterceptor(storage), // Runs 2nd for requests, 2nd for responses
    ErrorInterceptor(),       // Runs 3rd for requests, 1st for responses
  ],
);
```

**For requests:** Top to bottom  
**For responses:** Bottom to top (reverse order)

:::tip
**Order Matters**: Place interceptors that modify requests (like auth) before logging interceptors to see the final request being sent.
:::

---

## Common Interceptor Patterns

### 1. Request Headers Interceptor

Add custom headers to all requests:

```dart
class HeadersInterceptor implements HttpInterceptor {
  const HeadersInterceptor(this.headers);

  final Map<String, String> headers;

  @override
  void onRequest(HttpRequest request) {
    request.headers.addAll(headers);
  }

  @override
  void onResponse(HttpResponse response) {}
}

// Usage
final client = HttpPackageClient(
  interceptors: [
    HeadersInterceptor({
      'X-App-Version': '1.0.0',
      'X-Platform': 'Flutter',
      'Accept-Language': 'en-US',
    }),
  ],
);
```

### 2. Performance Monitoring

Track request timing:

```dart
class PerformanceInterceptor implements HttpInterceptor {
  final Map<String, DateTime> _requestTimes = {};

  @override
  void onRequest(HttpRequest request) {
    _requestTimes[request.url.toString()] = DateTime.now();
    print('⏱️  Starting: ${request.method} ${request.url}');
  }

  @override
  void onResponse(HttpResponse response) {
    final url = response.request.url.toString();
    final startTime = _requestTimes.remove(url);

    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      print('⏱️  Completed in ${duration.inMilliseconds}ms: $url');

      if (duration.inMilliseconds > 1000) {
        print('⚠️  Slow request detected!');
      }
    }
  }
}
```

### 3. Caching Interceptor

Cache responses for offline use:

```dart
class CacheInterceptor implements HttpInterceptor {
  CacheInterceptor(this.storage);

  final Storage storage;

  @override
  void onRequest(HttpRequest request) {
    // Check cache before request (in a real implementation)
    print('Checking cache for ${request.url}');
  }

  @override
  Future<void> onResponse(HttpResponse response) async {
    if (response.statusCode == 200 && response.request.method == 'GET') {
      // Cache successful GET responses
      final cacheKey = 'cache_${response.request.url}';
      final responseData = await response.stream.join();

      await storage.save(cacheKey, responseData);
      print('Cached response for ${response.request.url}');
    }
  }
}
```

### 4. User Agent Interceptor

Add user agent information:

```dart
class UserAgentInterceptor implements HttpInterceptor {
  UserAgentInterceptor({
    required this.appName,
    required this.appVersion,
    required this.platform,
  });

  final String appName;
  final String appVersion;
  final String platform;

  @override
  void onRequest(HttpRequest request) {
    request.headers['User-Agent'] = '$appName/$appVersion ($platform)';
  }

  @override
  void onResponse(HttpResponse response) {}
}

// Usage
final client = HttpPackageClient(
  interceptors: [
    UserAgentInterceptor(
      appName: 'MyApp',
      appVersion: '1.0.0',
      platform: 'Android',
    ),
  ],
);
```

### 5. Debug Interceptor

Detailed debugging information in development:

```dart
class DebugInterceptor implements HttpInterceptor {
  const DebugInterceptor({this.enabled = true});

  final bool enabled;

  @override
  void onRequest(HttpRequest request) {
    if (!enabled) return;

    print('╔══════════════════════════════════════════════════════════');
    print('║ REQUEST');
    print('╠══════════════════════════════════════════════════════════');
    print('║ ${request.method} ${request.url}');
    print('║ Headers:');
    request.headers.forEach((key, value) {
      print('║   $key: $value');
    });
    if (request.body.isNotEmpty) {
      print('║ Body:');
      print('║   ${request.body}');
    }
    print('╚══════════════════════════════════════════════════════════');
  }

  @override
  void onResponse(HttpResponse response) {
    if (!enabled) return;

    print('╔══════════════════════════════════════════════════════════');
    print('║ RESPONSE');
    print('╠══════════════════════════════════════════════════════════');
    print('║ ${response.statusCode} ${response.reasonPhrase}');
    print('║ Headers:');
    response.headers.forEach((key, value) {
      print('║   $key: $value');
    });
    print('╚══════════════════════════════════════════════════════════');
  }
}
```

---

## Accessing Request and Response Data

### HttpRequest Properties

The `HttpRequest` object provides:

```dart
class HttpRequest {
  String method;              // GET, POST, PUT, DELETE, etc.
  Uri url;                    // Full request URL
  Map<String, String> headers; // Request headers (mutable)
  String body;                // Request body as string
  List<int>? bodyBytes;       // Request body as bytes
  Encoding? encoding;         // Body encoding
  int? contentLength;         // Content length
}
```

**Example - Modifying a request:**

```dart
@override
void onRequest(HttpRequest request) {
  // Add headers
  request.headers['X-Custom-Header'] = 'value';

  // Modify URL (though url property is final, you can inspect it)
  print('Requesting: ${request.url.path}');

  // Access method
  if (request.method == 'POST') {
    print('POST request body: ${request.body}');
  }
}
```

### HttpResponse Properties

The `HttpResponse` object provides:

```dart
class HttpResponse {
  HttpRequest request;           // Original request
  int statusCode;                // HTTP status code (200, 404, etc.)
  Map<String, String> headers;   // Response headers
  bool persistentConnection;     // Keep-alive status
  String? reasonPhrase;          // Status text ("OK", "Not Found", etc.)
  int? contentLength;            // Response content length
  Stream<List<int>> stream;      // Response body stream
}
```

**Example - Reading response:**

```dart
@override
Future<void> onResponse(HttpResponse response) async {
  // Check status
  if (response.statusCode == 200) {
    print('Success!');
  }

  // Access headers
  final contentType = response.headers['content-type'];
  print('Content-Type: $contentType');

  // Get original request
  print('Response for: ${response.request.url}');
}
```

---

## What's Next?

Now that you understand HTTP interceptors, explore these related topics:

- **[Storage](/constructs/revali_client/getting-started/storage)** - Manage cookies and persistent data
- **[Return Types](/constructs/revali_client/getting-started/return-types)** - Handle custom data types
- **[Generated Code](/constructs/revali_client/generated-code)** - Understand the client structure
- **[Configure](/constructs/revali_client/getting-started/configure)** - Customize client generation
