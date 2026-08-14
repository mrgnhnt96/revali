---
title: Error Responses
description: Return a machine-readable error code that survives the hop to the caller
---

A status code tells the caller that something went wrong. It does not tell them *what*.

Two different 404s — an unknown user and an unknown organization — look identical from the outside. A service calling you has exactly two options: give up, or match on the human-readable message you happened to write, which was never meant to be an API and will change the first time somebody improves the wording. `HttpError` closes that gap by carrying a stable `code` alongside the status, so the caller can branch on the thing that actually differs.

## Throwing an `HttpError`

`HttpError` lives in `package:revali_core` and is re-exported by `package:revali_router`, so a controller already has it in scope:

<CodeFile name="routes/controllers/user_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UserController {
  const UserController();

  @Get(':id')
  Future<User> get(@Param() String id) async {
    final user = await userService.find(id);

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

Named constructors cover the statuses that come up most often:

| Constructor | Status |
| --- | --- |
| `HttpError.badRequest` | 400 |
| `HttpError.unauthorized` | 401 |
| `HttpError.forbidden` | 403 |
| `HttpError.notFound` | 404 |
| `HttpError.conflict` | 409 |
| `HttpError.unprocessable` | 422 |
| `HttpError.internal` | 500 |

For anything else, the unnamed constructor takes `statusCode` directly:

```dart
throw const HttpError(
  statusCode: 429,
  code: 'rate_limited',
  message: 'Too many requests',
  details: {'retryAfter': 30},
);
```

Every constructor is `const`, so an error with no interpolated values can be a compile-time constant.

### The four fields

- **`statusCode`** — the HTTP status this failure responds with.
- **`code`** — a stable, machine-readable identifier: `user_not_found`, not `User not found`. This is the part callers branch on.
- **`message`** — a human-readable explanation, for logs and developers. It is free to change wording without notice, which is precisely why `code` exists. Never parse it.
- **`details`** — extra machine-readable context: which field failed validation, how long to wait. It crosses the wire to whoever called you, so keep internals out of it. Defaults to `{}`.

<Callout type="warning">

Treat `code` as API. Renaming it breaks callers exactly as renaming a route would — and nothing catches it for you. The contract check (`revali routes --check`) reports *route* drift, not error-code drift, so a code you quietly stop emitting is a silent break for everyone matching on it.

</Callout>

## The wire format

An uncaught `HttpError` responds with its own status and a JSON body nested under `error`:

```json
{
  "error": {
    "code": "user_not_found",
    "message": "No user with id 7",
    "details": {"id": "7"}
  }
}
```

`details` is omitted entirely when it is empty, rather than serialized as `null` or `{}` — a caller checking for its presence gets a useful answer. The response is `application/json`, the same as any other map-shaped body.

The nesting is deliberate: it mirrors the `{"data": ...}` wrapper that successful JSON responses already use, so a caller reads one envelope shape for both outcomes and only has to look at which key is present.

## It is opt-in, and it does not override your catchers

Nothing about the framework's existing plain-text defaults changes. A handler that throws a `StateError`, or anything else that is not an `HttpError`, still gets the [default response](/revali/app-configuration/default-responses) it always got — a 500 with a plain-text body. A caller sees the envelope only for handlers that chose to raise one, so a client reading today's responses keeps working after you adopt this.

The same applies to [exception catchers](/constructs/revali_server/lifecycle-components/advanced/exception-catchers). The envelope is a **fallback for an unclaimed error, not an override**: the router runs the catcher chain first, and only reaches for `toEnvelope()` when no catcher handled the exception. An app that registered a catcher for its own `HttpError` subtype still wins, and can respond with whatever shape it likes.

```dart
final class BillingErrorCatcher extends ExceptionCatcher<HttpError> {
  const BillingErrorCatcher();

  @override
  ExceptionCatcherResult<HttpError> catchException(
    HttpError exception,
    Context context,
  ) {
    // This claims the error, so the default envelope never runs for it.
    return ExceptionCatcherResult.handled(
      statusCode: 402,
      body: {'billing': exception.code},
    );
  }
}
```

## Reading it back with `revali_client`

The other half of the hop. A generated `revali_client` throws `ServerException` for any non-2xx response, and it reads the error envelope when the peer sent one:

```dart
try {
  final user = await client.users.get(id: '1');
} on ServerException catch (e) {
  if (e.code == 'user_not_found') {
    // Branch on the code, not on a status shared with every other 404.
    return null;
  }

  rethrow;
}
```

| Field | Meaning |
| --- | --- |
| `statusCode` | The HTTP status. Always present. |
| `message` | The HTTP reason phrase. Always present. |
| `body` | The raw response body. Always available. |
| `code` | The peer's stable error identifier, or `null` if it sent no envelope. |
| `reason` | The peer's human-readable `message` from the envelope, or `null`. |
| `details` | The envelope's `details` map, or `null`. |
| `isStructured` | Whether the peer sent an envelope — that is, whether `code` is non-null. |

Note that the envelope's `message` arrives as `reason`, not `message`: `ServerException.message` was already the HTTP reason phrase before any of this existed, and renaming it would have broken every existing `catch`.

### Parsing is best-effort on purpose

This code runs against whatever another service actually sent — a plain-text response, an intermediary's HTML error page, a third-party API with its own shape, or a truncated body. None of those are your bug to surface as a parse failure, so a body that is not JSON, or is JSON without a map-shaped `error` key, leaves `code`, `reason` and `details` null and falls back to `statusCode` plus the raw `body`. A malformed body surfaces as the HTTP failure it already is, never as a `FormatException` thrown from inside the client.

The practical consequence: `isStructured` is the check worth writing before you trust `code`. A peer that is not a Revali service — or is one that hasn't adopted `HttpError` yet — behaves exactly as it did before.

## Why there are no generated typed exceptions

A reasonable next step would be for the client generator to emit one exception class per error a given endpoint can raise, so `client.users.get()` could be caught as `UserNotFoundException` and the compiler would check the branches for you. That was deliberately not built.

It would require every handler to declare up front which errors it can raise — an annotation on the method, plus a route contract that carries the declarations through generation to the client. That is a real surface area to design, and one that goes stale the moment a handler throws something it forgot to declare: the generated type would then promise coverage it does not have, which is worse than no promise.

`HttpError.code` gets most of the value without any of that. It is a string comparison instead of a type check, but it is honest about what the server actually sends, and it does not foreclose the typed version later — the codes are already the thing a generated exception would be named after.

## Next Steps

- **[Default Responses](/revali/app-configuration/default-responses)**: Customize the plain-text responses used when no `HttpError` is thrown
- **[Exception Catchers](/constructs/revali_server/lifecycle-components/advanced/exception-catchers)**: Claim an exception before the default envelope runs
- **[Generated Code](/constructs/revali_client/generated-code)**: What `revali_client` generates for your controllers
