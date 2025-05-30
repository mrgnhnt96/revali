---
title: Interceptors
description: Intercept HTTP requests and responses
sidebar_position: 3
---

# Interceptors

Revali Client supports intercepting HTTP requests and responses. This is useful for a variety of use cases, such as:

- Logging
- Authentication
- Cache Management

## Creating an Interceptor

To create an interceptor, you need to implement the `HttpInterceptor` interface. This interface has two methods: `onRequest` and `onResponse`.

```dart
import 'package:revali_client/revali_client.dart';

class MyInterceptor implements HttpInterceptor {
  const MyInterceptor();

  @override
  FutureOr<void> onRequest(HttpRequest request) async {
    print('Request: ${request.url}');
  }

  @override
  FutureOr<void> onResponse(HttpResponse response) async {
    print('Response: ${response.statusCode}');
  }
}
```

### Example

A great example of an interceptor is when the server returns a `401` (Unauthorized) response. When this happens, we want to clear the `Auth` cookie from the `Storage`.

```dart
class AuthInterceptor implements HttpInterceptor {
  const AuthInterceptor(this.storage);

  final Storage storage;

  @override
  void onRequest(HttpRequest request) {}

  @override
  Future<void> onResponse(HttpResponse response) async {
    if (response.statusCode == 401) {
      await storage.remove('Auth');
    }
  }
}
```
