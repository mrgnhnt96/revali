---
description: Methods define the behavior of an endpoint
sidebar_position: 1
---

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

:::important
You can only use one method annotation per endpoint.
:::

### Registering Endpoints

Each annotation accepts an optional argument to define the path of the endpoint. If no argument is provided, the path will be inferred from the controller's path.

```dart
@Get()
// or
@Get('path')
```

<!-- TODO(mrgnhnt): Reference how to create -->

## Custom Methods

If you need to define a custom http method, you can extend `Method` class:

```dart
import 'package:revali_router/revali_router.dart';

final class CustomMethod extends Method {
    const CustomMethod([String? path]) : super('CUSTOM', path: path);
}
```

## Paths

When defining an endpoint, the path of the endpoint will be prefixed with the path of the controller. Meaning if the controller is annotated with `@Controller('hello')`, all endpoints within the controller will be prefixed with `/hello`.

## Path Parameters

Path parameters can be defined in the path of the endpoint by using a `:` followed by the parameter name.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  // highlight-next-line
  @Get(':name')
  String sayHello(
    @Param() String name,
  ) {
    return 'Hello, $name!';
  }
}
```

Notice that the `name` parameter is annotated with `@Param()`. This annotation is used to bind the path parameter to the method's parameter.

:::tip
Check out [Binding][binding] to learn more about annotating parameters.
:::

### Controller Parameters

Path parameters are not limited to endpoints, you can also define them in the controller's path.

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Controller('shop/:shopId')
class ShopController ...
```

## Basic Usage

In the example below, we'll define a `GET` endpoint using the `Get` annotation.

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Controller('hello')
class HelloController {

  // highlight-next-line
  @Get()
  String sayHello() {
    return 'Hello, World!';
  }
}
```

The `sayHello` method has the `Get` annotation, exposing it as a `GET` endpoint. Since `Get` isn't provided an argument, the endpoint's path is inferred from the `Controller`'s path, resulting in a `GET` endpoint at `/hello`.

---

If you want to define a path for the endpoint, you can pass a path parameter to the `Get` annotation:

```dart
import 'package:revali_router/revali_router.dart';

// highlight-next-line
@Controller('hello')
class HelloController {

  // highlight-next-line
  @Get('world')
  String sayHello() {
    return 'Hello, World!';
  }
}
```

In the example above, the `sayHello` method is annotated with the `Get` annotation with a path parameter of `/world`, resulting in a `GET` endpoint at `/hello/world`.

:::tip
Notice that the path argument does not start with `/`, this will be automatically added.
:::

[binding]: ./binding.md
