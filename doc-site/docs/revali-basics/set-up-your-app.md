---
sidebar_position: 1
---

# Set Up Your App

Revali uses annotations to associate your code with the API side of things. The first thing you'll do is create a class (commonly called `App`), that extends `AppConfig`from `revali_router`. You'll need to provide it with your host and port number, and set up any dependencies you'll want to inject into your controllers later on.

**Don't worry, you can leave the `configureDependencies` method empty for now and register classes later on**

It's recommended that you create at least two entry points (`@App`'s); one for development -- where you specify localhost, and another for production. However, the `flavor` argument is optional and can be removed if you only have one class annotated with `@App`

## Example: Creating a Basic App

Create a file at `routes/dev.app.dart`:

** Note: the file name MUST end in `.app.dart`**

```dart title="routes/dev.app.dart"
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
