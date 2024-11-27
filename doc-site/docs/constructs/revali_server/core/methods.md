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
| `SSE`      | Defines a [`Server-Sent Event`][server-sent-events] endpoint.|
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

## Examples

### Get

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

### Post

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Post(':id')
  User createHello(
    @Param() String id,
  ) {
    return User(id);
  }
}
```

:::tip
Check out [Binding][binding] to learn more about annotating parameters.
:::

### Put

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Put(':id')
  User updateHello(
    @Param('id', UserPipe) User user,
    @Body.pipe(PutUserInputPipe) PutUserInput user,
  ) {
    // update user...
    return user;
  }
}
```

:::tip
Learn more:

- [Binding][binding] to learn more about annotating parameters.
- [Pipes][pipes] to learn more about transforming parameters from the request.

:::

### Patch

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Patch(':id')
  User patchHello(
    @Param() String id,
    @Body.pipe(PatchUserInputPipe) PatchUserInput user,
  ) {
    return user;
  }
}
```

:::tip
Learn more:

- [Binding][binding] to learn more about annotating parameters.
- [Pipes][pipes] to learn more about transforming parameters from the request.

:::

### Delete

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @Delete(':id')
  void deleteHello(
    @Param() String id,
  ) {
    // delete user...
  }
}
```

:::tip
Check out [Binding][binding] to learn more about annotating parameters.
:::

### SSE

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {

  @SSE('events')
  Stream<String> events() async* {
    yield 'Hello, World!';
  }
}
```

:::tip
Learn more about [Server-Sent Events][server-sent-events].
:::

[binding]: ./binding.md
[pipes]: ./pipes.md
[server-sent-events]: ../response/server-sent-events.md
