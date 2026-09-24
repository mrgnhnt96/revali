---
title: Response
description: How an endpoint's return value becomes the HTTP response, and how to change the body, status and headers
---

An endpoint's return value becomes the response body. Revali picks the wire format from the return type: most values are JSON-encoded and wrapped as `{"data": ...}`, while `StringContent`, bytes and streams are sent raw. To change the status code, headers or body from a [lifecycle component](/constructs/revali_server/lifecycle-components), use the `Response` object.

## Minimal example

<CodeFile name="routes/controllers/greeting_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('greeting')
class GreetingController {
  const GreetingController();

  @Get()
  String json() => 'Hello world!';

  @Get('text')
  StringContent text() => const StringContent('Hello world!');
}
```

</CodeFile>

```bash
curl -i http://localhost:8080/api/greeting
# content-type: application/json
# {"data":"Hello world!"}

curl -i http://localhost:8080/api/greeting/text
# content-type: text/plain
# Hello world!
```

## Return types

| Return type | Body | `Content-Type` |
| ----------- | ---- | -------------- |
| `void`, `Future<void>` | Empty, status `200` | none |
| `String`, `int`, `double`, `bool` | `{"data": value}` | `application/json` |
| `Map`, `List`, `Set`, `Iterable` | `{"data": [...]}` / `{"data": {...}}` | `application/json` |
| Class with `toJson()` | `{"data": toJson()}` | `application/json` |
| Record `(a, b)` | `{"data": [a, b]}` | `application/json` |
| Record `({a, b})` | `{"data": {"a": ..., "b": ...}}` | `application/json` |
| Record `(a, {b})` | `{"data": [a, {"b": ...}]}` | `application/json` |
| `StringContent` | The raw string | `text/plain` |
| `List<int>` | The raw bytes | `application/octet-stream` |
| `Stream<T>` | Each event written as it is produced; each event is encoded by the rules above | `application/octet-stream` |
| `Future<T>` | Same as `T` | same as `T` |

Nested custom types are converted too: `List<User>`, `Map<String, User>` and records containing `User` all call `User.toJson()`.

```dart
class User {
  const User({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}

@Get('users')
List<User> users() => const [User(name: 'Ada')];
```

`GET /api/greeting/users` returns `{"data":[{"name":"Ada"}]}`.

<Callout type="note">

A plain `String` return is JSON (`{"data":"..."}`), not text. Return `StringContent` to send text or HTML as-is.

</Callout>

## Errors

Throw to send an error response. An uncaught exception becomes `500`; a binding failure (`MissingArgumentException`) becomes `400`. For a specific status with a machine-readable body, throw an `HttpError`:

```dart
@Get('users/:id')
Future<User> user(@Param() String id) async {
  final user = await repo.find(id);
  if (user == null) {
    throw const HttpError.notFound(code: 'user_not_found', message: 'No such user');
  }
  return user;
}
```

```json
{"error": {"code": "user_not_found", "message": "No such user"}}
```

See [Error responses](/revali/app-configuration/default-responses#httperror) for `HttpError`, and [exception catchers](/constructs/revali_server/lifecycle-components/advanced/exception-catchers) to map your own exceptions.

## The `Response` object

`Response` is available as an implied parameter in endpoints and lifecycle components, and as `context.response`.

| Member | Type | Use |
| ------ | ---- | --- |
| `statusCode` | `int` (read/write) | See [Status code](/constructs/revali_server/response/status-code). |
| `headers` | `Headers` | See [Headers](/constructs/revali_server/response/headers). |
| `headers.setCookies` | `SetCookies` | See [Cookies](/constructs/revali_server/response/cookies). |
| `body` | `Body`; setter takes any supported value | Read with `body.data`, replace with `body = value`, add a key to a JSON body with `body['key'] = value`. |

Assigning `body` accepts the same values as a return type, plus `dart:io` `File` and `MemoryFile`. A `File` is streamed with `Content-Type` from its extension, `Content-Disposition: attachment; filename="..."`, `Last-Modified`, and `Range` support. A `MemoryFile` sends in-memory bytes with a given MIME type and file name:

```dart
import 'dart:io';

@Get('report')
void report(Response response) {
  response.body = File('reports/latest.pdf');
}

@Get('export')
void export(Response response) {
  response.body = MemoryFile.from(
    'id,name\n1,Ada\n',
    mimeType: 'text/csv',
    basename: 'users',
    extension: 'csv',
  );
}
```

Changing the body in a post-interceptor, after the handler has run:

```dart
class AddTimestamp implements LifecycleComponent {
  const AddTimestamp();

  InterceptorPostResult stamp(Response response) {
    response.body['timestamp'] = DateTime.now().toIso8601String();
  }
}
```

A value returned by the endpoint overwrites anything set on `response.body` inside the endpoint. Endpoints that set `response.body` themselves should return `void`.

Related: [Status code](/constructs/revali_server/response/status-code) · [Headers](/constructs/revali_server/response/headers) · [Cookies](/constructs/revali_server/response/cookies) · [Server-Sent Events](/constructs/revali_server/response/server-sent-events) · [WebSockets](/constructs/revali_server/response/websockets)
