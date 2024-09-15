# Advanced Features

## WebSockets

### Using Built-in WebSockets

Revali includes built-in support for WebSockets, allowing you to create WebSocket endpoints effortlessly.

#### Creating a WebSocket Handler

Create a class with methods annotated with `@WebSocket` to handle WebSocket connections and messages:

```dart
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/revali_router.dart';

class WebSocketHandlers {
  @WebSocket('/ws', mode: WebSocketMode.twoWay)
  Stream<String> onMessage(String message) async* {
    print('Received message: $message');
    yield 'Echo: $message';  // Echo the received message back to the client
  }
}
```

In this example, a WebSocket endpoint is created at the `/ws` path, and the method `onMessage` handles incoming messages by echoing them back.

#### Integrate WebSocket Handler into App Configuration

Define an `AppConfig` class and register your WebSocket handler within it:

```dart
import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
class DevApp extends AppConfig {
  DevApp() : super(host: 'localhost', port: 8080);

  @override
  Future<void> configureDependencies(DI di) async {
    di.registerLazySingleton((di) => WebSocketHandlers());
  }
}
```

#### Start the Server

In your main entry point, start the Revali server with WebSocket support:

```dart
import 'package:revali_router/revali_router.dart';

void main() async {
  final app = DevApp();

  final server = await app.createServer();
  await server.listen();

  print('Server running on ${app.host}:${app.port}');
}
```

## Interceptors and Middleware

### Creating and Using Interceptors

Interceptors allow you to pre-process and post-process requests globally or on a per-route basis.

```dart
@Interceptor()
class MyInterceptor {
  Future<void> intercept(InterceptorContext context) async {
    // Pre-processing logic
    print('Before handling request');

    await context.next();  // Proceed to the next interceptor or the controller

    // Post-processing logic
    print('After handling request');
  }
}
```

Register the interceptor in your `AppConfig`:

```dart
@App(flavor: 'dev')
class DevApp extends AppConfig {
  @override
  Future<void> configureDependencies(DI di) async {
    di.registerMiddleware((di) => MyInterceptor());
  }
}
```

## Guards

### Protecting Routes with Guards

Guards are used to protect routes and run before the request reaches the controller.

```dart
@Guard()
class AuthGuard implements CanActivate {
  @override
  Future<bool> canActivate(RequestContext context) async {
    // Authentication logic here
    final String? authHeader = context.request.headers['Authorization'];
    return authHeader == 'valid-token';  // Allow or deny access
  }
}

@Controller('protected')
@UseGuards([AuthGuard])
class ProtectedController {
  @Get()
  Future<String> getProtectedResource() async {
    return 'This is protected content';
  }
}
```

This ensures that only authenticated requests can access certain routes.
