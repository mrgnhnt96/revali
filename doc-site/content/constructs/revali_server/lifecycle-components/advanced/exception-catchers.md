---
title: Exception Catchers
description: Turn exceptions thrown during a request into error responses.
---

An exception catcher turns an exception into an error response. When anything in the lifecycle throws (middleware, a guard, an interceptor, a pipe, or the endpoint), Revali stops the request and asks the catchers, in order, whether they handle that exception. Use catchers to map your domain exceptions (`NotFound`, `ValidationFailed`, ...) to status codes in one place instead of in every endpoint.

<Callout type="tip">

For a standard `{"error": {"code": ..., "message": ...}}` response, you can throw an [`HttpError`][http-error] without writing a catcher.

</Callout>

## Example

<CodeFile name="lib/components/not_found_catcher.dart">

```dart
import 'package:revali_router/revali_router.dart';

class NotFound implements Exception {
  const NotFound(this.what);

  final String what;
}

class NotFoundCatcher implements LifecycleComponent {
  const NotFoundCatcher();

  ExceptionCatcherResult<NotFound> notFound(NotFound exception) {
    return ExceptionCatcherResult.handled(
      statusCode: 404,
      body: {'message': '${exception.what} not found'},
    );
  }
}
```

</CodeFile>

<CodeFile name="routes/apps/my_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@NotFoundCatcher()
@App()
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8080);
}
```

</CodeFile>

<CodeFile name="routes/controllers/users_controller.dart">

```dart
@Controller('users')
class UsersController {
  const UsersController();

  @Get(':id')
  User get(@Param() String id) => throw const NotFound('User');
}
```

</CodeFile>

`GET /api/users/42` responds with `404` and `{"message": "User not found"}`. In debug mode, a `"__DEBUG__"` key is added to that object.

## How Catchers Are Chosen

- The **type argument** of `ExceptionCatcherResult<T>` is the exception type the method handles. A parameter of type `T` receives the thrown exception.
- Catchers are tried **endpoint first, then controller, then app**, and the first `handled` result wins. See [Order of Execution][order].
- Return `ExceptionCatcherResult.unhandled()` to pass the exception on to the next catcher.
- Only `Exception` subtypes are passed to catchers. An `Error` (such as a `TypeError` or `StateError`) always becomes a `500`.
- Catcher methods must be **synchronous**. A method that returns `Future<ExceptionCatcherResult<T>>` is rejected when the code is generated.

## Results

| Result | Effect |
| --- | --- |
| `ExceptionCatcherResult.handled({statusCode, headers, body})` | This response is sent. The status defaults to `500`, or `400` for a `MissingArgumentException`. |
| `ExceptionCatcherResult.unhandled()` | Try the next catcher. It takes no arguments. |

`handled` takes the same arguments as the other error results. See [Error Responses][error-responses].

## When Nothing Catches It

| Exception | Response |
| --- | --- |
| `MissingArgumentException` (a required `@Query`, `@Body`, `@Header`, `@Data`, ... binding was missing or invalid) | `400 Bad Request` |
| [`HttpError`][http-error] | Its own status and `{"error": {...}}` envelope |
| Anything else | `500 Internal Server Error` |

To change these default bodies, see [Default Responses][default-responses].

## Classic Style

As an alternative, extend `ExceptionCatcher<T>` and implement `catchException`. `T` must be a specific exception type. `ExceptionCatcher<Exception>` never matches anything.

<CodeFile name="lib/components/not_found_catcher.dart">

```dart
import 'package:revali_router/revali_router.dart';

final class NotFoundCatcher extends ExceptionCatcher<NotFound> {
  const NotFoundCatcher();

  @override
  ExceptionCatcherResult<NotFound> catchException(NotFound exception, Context context) {
    return ExceptionCatcherResult.handled(statusCode: 404, body: '${exception.what} not found');
  }
}
```

</CodeFile>

For a catch-all, extend `DefaultExceptionCatcher`. It matches every `Exception` and is always tried after all other catchers:

```dart
final class FallbackCatcher extends DefaultExceptionCatcher {
  const FallbackCatcher();

  @override
  ExceptionCatcherResult<Exception> catchException(Exception exception, Context context) {
    return const ExceptionCatcherResult.handled(statusCode: 500, body: 'Something went wrong');
  }
}
```

Apply classic catchers with `@NotFoundCatcher()`, or by type with `@Catches([NotFoundCatcher])`.

[order]: /constructs/revali_server/lifecycle-components#order-of-execution
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
[http-error]: /revali/app-configuration/default-responses#httperror
[default-responses]: /revali/app-configuration/default-responses
