---
title: Error Responses
description: Customize the default 400/404/500 responses, and throw HttpError for machine-readable error codes
---

When a request fails and no [exception catcher](/constructs/revali_server/lifecycle-components/advanced/exception-catchers) handles it, Revali sends one of two responses:

- **An `HttpError`** that your code throws is sent with its own status and a JSON body containing an error `code`. Use it when callers need to know *which* error happened.
- **Anything else** gets a default response: plain text, and 500 for an unhandled exception. Override `defaultResponses` on your app to change these.

## Default Responses

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  DefaultResponses get defaultResponses => DefaultResponses(
        notFound: SimpleResponse(404, body: {'error': 'not_found'}),
        internalServerError: SimpleResponse(
          500,
          body: 'Something went wrong. Please try again later.',
        ),
      );
}
```

</CodeFile>

Any response you don't set keeps its default:

| Parameter | Sent when | Default |
| --- | --- | --- |
| `internalServerError` | An unhandled exception | `500 Internal Server Error` |
| `notFound` | No route matches | `404 Not Found` |
| `badRequest` | A binding is missing or invalid (`MissingArgumentException`) | `400 Bad Request` |
| `failedCorsOrigin` | [`@AllowOrigins`](/constructs/revali_server/access-control/allow-origins) rejects the origin | `403 CORS policy does not allow access from this origin.` |
| `failedCorsHeaders` | A CORS header check fails | `403 CORS policy does not allow access with these headers.` |

`SimpleResponse(statusCode, {headers, body})` takes the status code as a positional argument. A `Map` or `List` body is sent as JSON, and a `String` body as plain text.

In [debug mode](/revali/cli/dev#debug-mode-default), error bodies also include a `__DEBUG__` block with the exception and stack trace. Profile and release builds leave it out.

## `HttpError`

Throw an `HttpError` to send a stable, machine-readable `code` along with the status. Two different 404s (an unknown user and an unknown organization) then look different to the caller:

<CodeFile name="routes/controllers/user_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UserController {
  const UserController(this._users);

  final UserService _users;

  @Get(':id')
  Future<User> get(@Param() String id) async {
    final user = await _users.find(id);

    if (user == null) {
      throw HttpError.notFound(
        code: 'user_not_found',
        message: 'No user with id $id',
        details: {'id': id},
      );
    }

    return user;
  }
}
```

</CodeFile>

The response keeps the status, and the body is wrapped in `error`, the same way successful responses are wrapped in `data`:

```json
{
  "error": {
    "code": "user_not_found",
    "message": "No user with id 7",
    "details": {"id": "7"}
  }
}
```

| Field | Description |
| --- | --- |
| `statusCode` | The HTTP status. The named constructors set it for you. |
| `code` | A stable identifier that callers branch on, such as `user_not_found`. Treat it as part of your API. `revali routes --check` doesn't detect changes to codes. |
| `message` | A human-readable explanation. Callers should never parse it. |
| `details` | Extra machine-readable context, sent to the caller. Defaults to `{}`, and is left out of the body when empty. |

| Constructor | Status |
| --- | --- |
| `HttpError.badRequest` | 400 |
| `HttpError.unauthorized` | 401 |
| `HttpError.forbidden` | 403 |
| `HttpError.notFound` | 404 |
| `HttpError.conflict` | 409 |
| `HttpError.unprocessable` | 422 |
| `HttpError.internal` | 500 |
| `HttpError(statusCode: …)` | any |

Every constructor is `const`.

The `error` body is a fallback. Exception catchers run first, so a catcher registered for `HttpError`, or for a subtype of it, can send any shape it likes.

## Reading It with `revali_client`

A generated [`revali_client`](/constructs/revali_client) throws `ServerException` for any response that isn't 2xx:

```dart
try {
  await client.users.get(id: '1');
} on ServerException catch (e) {
  if (e.isStructured && e.code == 'user_not_found') return null;
  rethrow;
}
```

| Field | Value |
| --- | --- |
| `statusCode`, `message`, `body` | The HTTP status, the reason phrase, and the raw body. Always set. |
| `code`, `reason`, `details` | The `code`, `message` and `details` from the `error` body, or `null` if the body isn't in that shape. |
| `isStructured` | `true` when `code` is set |

A body that isn't in the `error` shape (plain text, an HTML error page, another API's format) never throws a parse error. It leaves `code`, `reason` and `details` as `null`.
