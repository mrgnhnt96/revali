# Getting Started

## Setup Your App

### Creating a Basic App

To get started, create a basic app by defining a class (commonly called `App`) that extends `AppConfig` from `revali_router`. Here’s a basic example:

```dart
// routes/dev.app.dart
import 'package:revali_router/revali_router.dart';

@AllowOrigins.all()
@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
        );

  @override
  Future<void> configureDependencies(DI di) async {}
}
```

**Note**: The file name must end in `.app.dart`.

### Starting the Server

In your main entry point, start the Revali server:

```dart
import 'package:revali_router/revali_router.dart';

void main() async {
  final app = DevApp();

  final server = await app.createServer();
  await server.listen();

  print('Server running on ${app.host}:${app.port}');
}
```

With this setup, you have created and started a basic Revali application. You can now proceed to define controllers, routes, and other functionalities to build out your application.
