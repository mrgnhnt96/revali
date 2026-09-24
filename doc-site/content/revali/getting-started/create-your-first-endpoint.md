---
title: Create Your First Endpoint
description: Write a controller, bind request data, and know exactly what the response looks like.
---

An endpoint is a method on a **controller**: a class annotated with
`@Controller` in a file under `routes/`. Revali finds it, generates the routing
code into `.revali/`, and serves it.

## Project layout

```tree
my_api/
├── pubspec.yaml
├── lib/                       # your models, services, components
└── routes/
    ├── controllers/
    │   └── hello_controller.dart
    └── apps/
        └── main_app.dart      # optional — see "Configure the app" below
```

Revali's rules for `routes/`:

- A controller file must end in `_controller.dart` or `.controller.dart`.
- An app file must be named `app.dart`, `*_app.dart` or `*.app.dart`.
- Subdirectories are fine; the directory names do **not** affect URLs.

## Write a controller

Create it by hand, or scaffold it with
[`dart run revali create controller`](/revali/cli/create):

<CodeFile name="routes/controllers/hello_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('hello')
class HelloController {
  const HelloController();

  @Get()
  String hello() => 'Hello, World!';

  @Get(':name')
  String greet(@Param() String name) => 'Hello, $name!';

  @Get('count')
  int count(@Query() int times) => times;
}
```

</CodeFile>

The URL is `/{prefix}/{controller path}/{method path}`. The prefix defaults to
`api`. The **method name is never part of the URL**: `@Get()` with no argument
serves the controller path itself.

| Request | Response |
| --- | --- |
| `GET /api/hello` | `200` `{"data": "Hello, World!"}` |
| `GET /api/hello/Ada` | `200` `{"data": "Hello, Ada!"}` |
| `GET /api/hello/count?times=3` | `200` `{"data": 3}` |
| `GET /api/hello/count` | `400` — the required `times` query parameter is missing |

## Responses

- A return value (string, number, map, list, record, or your own class) is
  JSON-encoded and wrapped in `{"data": ...}` with
  `Content-Type: application/json`.
- To send a body unwrapped, return `StringContent('...')` for plain text, or
  set `response.body` yourself.
- `Future<T>` and `Stream<T>` returns are awaited or streamed.

Details and overrides: [Response](/constructs/revali_server/response).

## Bind request data

Parameters are filled from the request by annotation:

| Annotation | Reads from | Example |
| --- | --- | --- |
| `@Param()` | A `:name` segment of the path | `@Param() String id` |
| `@Query()` | The query string | `@Query() int page` |
| `@Body()` | The request body (a key path with `@Body(['user', 'name'])`) | `@Body() User user` |
| `@Header('X-Name')` | A request header | `@Header('Authorization') String? auth` |

The parameter name is the key unless you pass one (`@Param('id') String userId`).
A nullable type makes the value optional. A missing or unparseable required
value produces `400 Bad Request` without your method running.

Your own classes work in bodies and responses when they have a
`fromJson` factory and a `toJson` method:

<CodeFile name="lib/models/user.dart">

```dart
class User {
  const User({required this.name});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(name: json['name'] as String);

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
```

</CodeFile>

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:my_api/models/user.dart';
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController();

  @Post()
  User create(@Body() User user) => user;
}
```

</CodeFile>

`POST /api/users` with `{"name": "Ada"}` returns `200` and
`{"data": {"name": "Ada"}}`.

The full binding reference, including cookies, custom binders and
dependency injection, is in [Binding](/constructs/revali_server/core/binding).

## Configure the app

Without an app file, Revali logs a warning and serves on `localhost:8080`
with the `/api` prefix. To choose the host, port or prefix, or to register
dependencies, add an app:

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080, prefix: 'api');
}
```

</CodeFile>

See [Create an App](/revali/app-configuration/create-an-app) for every option.

Next: [Run the server](/revali/getting-started/run-the-server).
