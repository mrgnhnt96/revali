# Revali Server

Revali Server is a "Server Construct" that generates server-side code for Revali applications. It provides a way to define routes, middleware, and other server-side logic in a type-safe way. Inspired by NestJS, Revali Server uses annotations to define routes, middleware, guards and other server-side logic.

## Example

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  const HelloController();

  @Get()
  String hello() {
    return 'Hello, World!';
  }
}
```

## Documentation

Check out the [documentation](https://www.revali.dev/constructs/revali_server/overview) for more information on how to use Revali Server.
