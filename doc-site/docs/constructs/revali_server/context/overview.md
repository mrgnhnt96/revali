---
sidebar_position: 0
description: The unified context object that provides access to request data, metadata, and more
---

# Context

The `Context` object is a unified interface that provides access to all the information and functionality needed by [Lifecycle Components](../lifecycle-components/overview.md). It contains the current request, response, metadata, data sharing, route information, and reflection capabilities.

## What Is Context?

Context is a single object that provides access to:

- **Request data** - Headers, body, query parameters, path parameters
- **Response control** - Setting status codes, headers, and body
- **Metadata management** - Request-scoped data and configuration
- **Data sharing** - Communication between lifecycle components
- **Route information** - Current route details and path information
- **Reflection utilities** - Runtime type information and introspection

## Using Context

While you can depend on the `Context` object directly in your lifecycle component methods, all of these properties can be [implicitly bound](../core/implied_binding.md). This means you can inject individual properties directly as method parameters instead of accessing them through the context object.

```dart
// Direct context access
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult processRequest(Context context) {
    final user = context.data.get<User>();
    final method = context.request.method;
    return const MiddlewareResult.next();
  }
}

// Implicit binding (recommended)
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult processRequest(Data data, Request request) {
    final user = data.get<User>();
    final method = request.method;
    return const MiddlewareResult.next();
  }
}
```

## Context Interface

The `Context` interface provides these properties:

```dart
abstract interface class Context {
  const Context();

  Data get data;           // Data sharing between components
  MetaScope get meta;      // Request metadata management
  RouteEntry get route;    // Current route information
  Request get request;     // HTTP request data
  Response get response;   // HTTP response control
  Reflect get reflect;     // Reflection utilities
}
```

## Context Properties

### `data` - Data Sharing

The `data` property provides a way to share data between different lifecycle components during a single request. It uses type-based storage where the type is the key.

:::tip
Learn more about [Data Sharing](./data-sharing.md) for detailed usage and examples.
:::

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult authHandler(Data data) {
    // Store data by type
    data.add<User>(currentUser);
    data.add<String>(generateId());

    return const MiddlewareResult.next();
  }

  GuardResult verifyUser(Data data) {
    // Access data by type
    final user = data.get<User>();
    final requestId = data.get<String>();

    return user != null && user.isAuthenticated
        ? const GuardResult.allow()
        : const GuardResult.deny();
  }
}
```

### `meta` - Metadata Management

The `meta` property provides access to request metadata and configuration. It uses type-based storage and supports both direct and inherited metadata.

:::tip
Learn more about [Meta](./meta.md) for detailed usage and examples.
:::

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult logRequest(MetaScope meta) {
    final public = meta.get<Public>();

    if (public != null) {
      print('Request is public');
    }

    return const MiddlewareResult.next();
  }
}
```

### `request` - Request Information

The `request` property provides access to the current HTTP request. Note that the request body must be resolved before accessing.

:::tip
Learn more about the [Request](../request/overview.md) for detailed usage and examples.
:::

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult processRequest(Request request) async {
    // Access request data
    final method = request.method;
    final uri = request.uri;
    final headers = request.headers;
    final queryParams = request.queryParameters;
    final pathParams = request.pathParameters;

    // Resolve payload before accessing body
    await request.resolvePayload();
    final body = request.body;

    return const MiddlewareResult.next();
  }
}
```

### `response` - Response Control

The `response` property allows you to control the HTTP response.

:::tip
Learn more about the [Response](../response/overview.md) for detailed usage and examples.
:::

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  InterceptorPostResult modifyResponse(Response response) {
    // Set response data
    response.statusCode = 200;
    response.headers.set('X-Custom-Header', 'value');
    response.body = 'Hello, World!';

    return const InterceptorPostResult.next();
  }
}
```

### `route` - Route Information

The `route` property provides information about the current route.

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  GuardResult checkRoute(RouteEntry route) {
    // Access route information
    final path = route.path;
    final method = route.method;
    final fullPath = route.fullPath;
    final parent = route.parent;

    print('Accessing route: $method $fullPath');
    return const GuardResult.allow();
  }
}
```

### `reflect` - Reflection Utilities

The `reflect` property provides runtime reflection capabilities for accessing metadata on properties of Return Types or Request Parameters.

:::tip
Learn more about the [Reflect Handler](./reflect.md) for detailed usage and examples.
:::

```dart
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult processWithReflection(Reflect reflect) {
    // Get reflector for a specific type
    final reflector = reflect.get<MyType>();
    if (reflector != null) {
      // Access metadata by key
      final meta = reflector.get('someProperty');
      // Use metadata...
    }

    return const MiddlewareResult.next();
  }
}
```

## Best Practices

### Directly Depend on What You Need

Instead of using the context object, directly depend on the specific properties you need as method parameters. This works even when you need multiple properties.

```dart
// ✅ Good - Direct dependencies for specific needs
class MyComponent implements LifecycleComponent {
  const MyComponent();

  GuardResult checkAuth(Request request, Data data) {
    final authHeader = request.headers.get('Authorization');
    final user = data.get<User>();
    return authHeader != null && user != null
        ? const GuardResult.allow()
        : const GuardResult.deny();
  }
}

// ✅ Good - Multiple properties when needed
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult processRequest(
    Request request,
    Response response,
    Data data,
    RouteEntry route,
  ) {
    // Use all the properties you need directly
    data.add<String>(generateId());
    response.headers.set('X-Request-ID', generateId());
    response.headers.set('X-Response-Time', getTimestamp());

    print('Processing ${request.method} ${route.fullPath}');
    return const MiddlewareResult.next();
  }
}

// ❌ Avoid - Using context when you only need specific properties
class MyComponent implements LifecycleComponent {
  const MyComponent();

  MiddlewareResult processRequest(Context context) {
    // Don't do this - use direct dependencies instead
    final method = context.request.method;
    final response = context.response;
    return const MiddlewareResult.next();
  }
}
```

## Related Topics

- **[Lifecycle Components](../lifecycle-components/overview.md)** - Learn about different lifecycle components
- **[Request](../request/overview.md)** - Detailed request object documentation
- **[Response](../response/overview.md)** - Detailed response object documentation
- **[Data Sharing](./data-sharing.md)** - Learn about data sharing patterns
