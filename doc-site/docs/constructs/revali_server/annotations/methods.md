# Methods

A method (or verb) is a http method used to define the behavior of an endpoint. Revali provides a set of annotations to define the http methods for your endpoints.

## Annotations

Revali Router provides the following annotations to define the http methods for your endpoints:

| Annotation | Description                |
|------------|----------------------------|
| `Get`      | Defines a `GET` endpoint.  |
| `Post`     | Defines a `POST` endpoint. |
| `Put`      | Defines a `PUT` endpoint.  |
| `Patch`    | Defines a `PATCH` endpoint.|
| `Delete`   | Defines a `DELETE` endpoint.|
| `WebSocket`| Defines an endpoint for a websocket.|

<!-- TODO(mrgnhnt): Reference how to create -->

If you need to define a custom http method, you can use the `Method` annotation:

```dart
import 'package:revali_router/revali_router.dart';

final class CustomMethod extends Method {
    const CustomMethod([String? path]) : super('CUSTOM', path: path);
}
```

## Example Usage

In the example below, we'll define a `GET` endpoint using the `Get` annotation.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Get()
  String sayHello() {
    return 'Hello, World!';
  }
}
```

The `sayHello` method is annotated with the `Get` annotation, exposing it as a `GET` endpoint. Since the method isn't provided an argument, the endpoint's path is inferred from the `Controller`'s path, resulting in a `GET` endpoint at `/hello`.

---

If you want to define a path for the endpoint, you can pass a path parameter to the `Get` annotation:

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Get('/world')
  String sayHello() {
    return 'Hello, World!';
  }
}
```

In the example above, the `sayHello` method is annotated with the `Get` annotation with a path parameter of `/world`, resulting in a `GET` endpoint at `/hello/world`.
