---
title: Binding
description: Get path, query, header, cookie, body and injected values into endpoint parameters
---

Binding fills an endpoint's parameters from the request. Annotate a parameter with where the value comes from (`@Param()`, `@Query()`, `@Body()`, ...) and Revali extracts it, converts it to the parameter's type, and passes it in. A few framework types, such as `Request` or `Headers`, need no annotation at all (see [Implied binding](#implied-binding)).

## Minimal example

<CodeFile name="routes/controllers/search_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('shops/:shopId')
class SearchController {
  const SearchController();

  @Post('search')
  Map<String, dynamic> search(
    @Param() String shopId,
    @Query() int? limit,
    @Header('X-Client') String? client,
    @Body(['term']) String term,
  ) {
    return {'shopId': shopId, 'limit': limit, 'client': client, 'term': term};
  }
}
```

</CodeFile>

```bash
curl -X POST 'http://localhost:8080/api/shops/abc/search?limit=5' \
  -H 'X-Client: cli' \
  -H 'Content-Type: application/json' \
  -d '{"term": "shoes"}'
# {"data":{"shopId":"abc","limit":5,"client":"cli","term":"shoes"}}
```

## Annotations

| Annotation | Reads from | Default key | Value type before conversion |
| ---------- | ---------- | ----------- | ---------------------------- |
| `@Param([name])` | Path segment `:name` | parameter name | `String` (`List<String>` for `*name`) |
| `@Query([name])` | Query string, last value wins | parameter name | Coerced: `int`, `double`, `bool`, JSON, else `String` |
| `@Query.all([name])` | Query string, every value | parameter name | List of coerced values |
| `@Header([name])` | Request header; repeated values joined with `, ` | parameter name | `String` |
| `@Header.all([name])` | Request header, every value | parameter name | `List<String>` |
| `@Cookie([name])` | Request cookie | parameter name | `String` |
| `@Body([path])` | Request body, optionally a nested key path | whole body | Decoded by `Content-Type` ([Request body](/constructs/revali_server/request/body)) |
| `@Ip()` | Client IP | n/a | `String?` |
| `@Dep()` | Dependency injection container | n/a | registered instance |
| `@Data()` | Request-scoped [data handler](/constructs/revali_server/context/data-sharing) | n/a | stored instance of the parameter's type |
| Custom `Bind<T>` / `@Binds(Type)` | Your code | n/a | `T` |

Every value-reading annotation also has a pipe form that runs a [pipe](/constructs/revali_server/core/pipes) on the raw value: `@Param.pipe(P)`, `@Query.pipe(P)`, `@Query.allPipe(P)`, `@Header.pipe(P)`, `@Header.allPipe(P)`, `@Cookie.pipe(P)`, `@Body.pipe(P)`, `@Ip.pipe(P)`. The long forms take both: `@Query('q', P)`, `@Body(['user'], P)`.

One binding annotation per parameter.

## Conversion and missing values

After extraction Revali converts the value to the parameter type:

- **Matching type**: passed through. `@Query() int limit` receives `5` for `?limit=5`, because query values are coerced.
- **`String` parameter, coerced value**: stringified. `@Query() String id` receives `"5"` for `?id=5`; leading zeros are kept (`?id=007` gives `"007"`).
- **`double` parameter, `int` value**: widened. `?n=5` gives `5.0`.
- **Class with `fromJson`**: the value is passed to `fromJson` (a factory or static method with exactly one parameter).
- **`Set<T>` parameter**: matched as an iterable and converted, since JSON has no sets.

If the value is missing or has the wrong type:

| Parameter | Result |
| --------- | ------ |
| Has a default value | The default is used. |
| Nullable (`String?`) | `null` is passed. |
| Required and non-nullable | `MissingArgumentException` is thrown and the client gets **HTTP 400**. |

For `@Query() String name` on a request without `?name=`, the response is `400` with a plain-text body:

```text
Bad Request

__DEBUG__:
Error: MissingArgumentException: key: name, location: @query, expected: String ...
```

The `__DEBUG__` section is only included in debug builds. To change the body, use an [exception catcher](/constructs/revali_server/lifecycle-components/advanced/exception-catchers).

## `@Param()` - Path parameters

Reads a `:name` segment declared in the controller or method path ([path syntax](/constructs/revali_server/core/methods#path-syntax)).

```dart
@Controller('shop/:shopId')
class ShopController {
  const ShopController();

  @Get('product/:productId')
  String product(@Param('productId') String id) => id;
}
```

`GET /api/shop/123/product/456` returns `{"data":"456"}`.

- Path values are always `String` and are not coerced. `@Param() int id` receives a `String` and responds `400`; use a [pipe](/constructs/revali_server/core/pipes) to convert.
- A wildcard segment `*path` binds to `@Param() List<String> path`.

## `@Query()` - Query parameters

```dart
@Get('search')
String search(
  @Query('q') String term,
  @Query() int? page,
  @Query.all('tag') List<String>? tags,
) => '$term $page $tags';
```

| Request | `term` | `page` | `tags` |
| ------- | ------ | ------ | ------ |
| `?q=dart` | `"dart"` | `null` | `null` |
| `?q=dart&page=2&tag=a&tag=b` | `"dart"` | `2` | `["a", "b"]` |
| `?q=dart&q=flutter` | `"flutter"` (last wins) | `null` | `null` |
| no `q` | 400 | | |

## `@Header()` - Request headers

```dart
@Get('profile')
String profile(
  @Header('Authorization') String? auth,
  @Header.all('X-Tag') List<String>? tags,
) => '$auth $tags';
```

- Header values are `String`s and are not coerced.
- With `@Header()`, a header sent more than once is joined: `X-Tag: a` + `X-Tag: b` gives `"a, b"`.
- Without a name, the parameter name is used as the header name, so name the header explicitly for anything containing `-`.

## `@Cookie()` - Request cookies

```dart
@Get('me')
String me(@Cookie('session') String? session) => session ?? 'anonymous';
```

Setting cookies is covered in [Cookies](/constructs/revali_server/response/cookies).

## `@Ip()` - Client IP

Injects the resolved client IP, the same value as [`request.ip`](/constructs/revali_server/request/client-ip).

```dart
@Post('login')
String login(@Ip() String? clientIp) => 'login from $clientIp';
```

By default this is the TCP remote address. Behind a reverse proxy, override `trustedProxy` on your app so Revali reads `X-Forwarded-For` and similar headers; see [Client IP](/constructs/revali_server/request/client-ip).

## `@Body()` - Request body

`@Body()` binds the whole decoded body. `@Body(['a', 'b'])` binds the value at `body['a']['b']`.

```dart
class CreateUser {
  const CreateUser({required this.name, required this.age});

  factory CreateUser.fromJson(Map<String, dynamic> json) => CreateUser(
        name: json['name'] as String,
        age: json['age'] as int,
      );

  final String name;
  final int age;
}

@Controller('users')
class UsersController {
  const UsersController();

  @Post()
  String create(@Body() CreateUser user) => '${user.name} ${user.age}';

  @Post('email')
  String email(@Body(['data', 'email']) String email) => email;
}
```

```bash
curl -X POST http://localhost:8080/api/users \
  -H 'Content-Type: application/json' -d '{"name": "Ada", "age": 36}'
# {"data":"Ada 36"}

curl -X POST http://localhost:8080/api/users/email \
  -H 'Content-Type: application/json' -d '{"data": {"email": "ada@example.com"}}'
# {"data":"ada@example.com"}
```

`@Body() Stream<List<int>>` receives the raw, unbuffered byte stream (no key path allowed). Content types, multipart uploads and custom parsers are on the [Request body](/constructs/revali_server/request/body) page.

## `@Dep()` - Dependency injection

Injects an instance registered in your app's [dependencies](/revali/app-configuration/configure-dependencies).

```dart
@Get(':id')
Future<User> get(@Param() String id, @Dep() UserService users) => users.find(id);
```

- On endpoint parameters `@Dep()` is required. An unannotated, non-nullable service parameter fails the build.
- On controller and lifecycle component constructors, `@Dep()` is implied and can be omitted.
- To pass a dependency as an argument to an annotation (for example a lifecycle component), use the [`Inject`](/revali/app-configuration/configure-dependencies) marker class instead.

## `@Data()` - Request-scoped data

Reads a value that a middleware or guard stored with `data.add(value)`. Lookup is by type.

```dart
@Get('profile')
String profile(@Data() User user) => user.name;
```

Missing data returns `400` unless the parameter is nullable. See [Data sharing](/constructs/revali_server/context/data-sharing).

## Custom binding

Implement `Bind<T>` when a value needs custom extraction logic.

<CodeFile name="lib/bindings/current_user.dart">

```dart
import 'dart:async';

import 'package:revali_router/revali_router.dart';

class CurrentUser implements Bind<User> {
  const CurrentUser();

  @override
  FutureOr<User> bind(BindContext context) {
    final token = context.request.headers.get('Authorization');
    return User.fromToken(token);
  }
}
```

</CodeFile>

Use it in one of two ways:

| Form | When | Construction |
| ---- | ---- | ------------ |
| `@CurrentUser() User user` | The class has a `const` constructor with constant arguments. | The annotation instance itself is used. |
| `@Binds(CurrentUser) User user` | The constructor needs services. | Revali builds the class, resolving constructor parameters from DI. |

`BindContext` exposes the full request [context](/constructs/revali_server/context) (`request`, `response`, `data`, `meta`, ...) plus `nameOfParameter` and `parameterType`.

## Implied binding

These parameter types are provided without an annotation, in endpoints and in [lifecycle component](/constructs/revali_server/lifecycle-components) methods:

| Type | Value |
| ---- | ----- |
| `Request` | The incoming [request](/constructs/revali_server/request) |
| `RequestHeaders` | Request headers |
| `RequestCookies` | Request cookies |
| `Response` | The outgoing [response](/constructs/revali_server/response) |
| `Headers`, `ResponseHeaders` | **Response** headers (writable) |
| `Cookies`, `ResponseCookies` | **Response** cookies |
| `SetCookies` | Response `Set-Cookie` values ([Cookies](/constructs/revali_server/response/cookies)) |
| `Body`, `PayloadBody` | Response body |
| `Context` | The whole request [context](/constructs/revali_server/context) |
| `Data` | [Data handler](/constructs/revali_server/context/data-sharing) |
| `Meta`, `MetaScope` | Route [metadata](/constructs/revali_server/context/meta) |
| `RouteEntry` | The matched route |
| `Reflect` | [Reflection](/constructs/revali_server/context/reflect) data |
| `CleanUp` | Register callbacks that run when the request closes |
| `DI` | The [dependency injection](/revali/app-configuration/configure-dependencies) container |

In [WebSocket](/constructs/revali_server/response/websockets) handlers, `AsyncWebSocketSender<T>` and `CloseWebSocket` are also implied.

```dart
@Get('debug')
String debug(Request request, Headers headers) {
  headers.set('X-Debug', 'true');
  return '${request.method} ${request.uri.path}';
}
```

<Callout type="caution">

`Headers` and `Cookies` in an endpoint are the **response** headers and cookies. To read what the client sent, use `@Header()`, `@Cookie()`, `RequestHeaders` or `RequestCookies`.

</Callout>

Prefer a binding annotation over reading `Request` by hand: the endpoint's inputs stay visible in its signature, and missing values produce a `400` automatically.

Next: [Pipes](/constructs/revali_server/core/pipes) · [Request body](/constructs/revali_server/request/body)
