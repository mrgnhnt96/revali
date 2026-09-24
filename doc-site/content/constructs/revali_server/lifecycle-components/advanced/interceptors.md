---
title: Interceptors
description: Run code just before the endpoint (pre) and just after it (post), for example to add request data or change the response.
---

An interceptor runs code right around the endpoint. The **pre** part runs after the guards, just before the endpoint. The **post** part runs after the endpoint has returned, so it can read and change the response. Use interceptors to add data the endpoint needs, add response headers, or reshape a response body.

Interceptors can't stop a request by returning a result. To reject a request, use [middleware][middleware] or a [guard][guards], or throw an exception.

## Example

<CodeFile name="lib/components/timing.dart">

```dart
import 'package:revali_router/revali_router.dart';

class Timing implements LifecycleComponent {
  const Timing();

  InterceptorPreResult start(Data data) {
    data.add(Stopwatch()..start());
  }

  InterceptorPostResult stop(Data data, Headers headers) {
    final watch = data.get<Stopwatch>();
    if (watch != null) {
      headers.set('X-Elapsed-Ms', '${watch.elapsedMilliseconds}');
    }
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/hello_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Timing()
@Controller('hello')
class HelloController {
  const HelloController();

  @Get()
  String hello() => 'world';
}
```

</CodeFile>

```http
GET /api/hello

HTTP/1.1 200 OK
x-elapsed-ms: 0
content-type: application/json

{"data":"world"}
```

`Headers` is the **response** headers. To read request headers, bind `RequestHeaders` or use `@Header()`.

## Pre and Post

| Return type | Runs | Order |
| --- | --- | --- |
| `InterceptorPreResult` | After all guards, before pipes and the endpoint | Registration order |
| `InterceptorPostResult` | After the endpoint returns | Reverse registration order |

Both types are aliases for `FutureOr<void>`, so the method returns nothing. Mark it `async` to await inside it, and keep the alias as the return type so Revali recognizes the role.

- Post interceptors **don't run** when the endpoint (or anything before it) throws. The exception goes to the [exception catchers][catchers] instead.
- In a post interceptor, `Response` holds the body the endpoint produced, already wrapped as `{"data": ...}`. You can replace it with `response.body = ...`. [Reflect][reflect] shows an example that strips private fields this way.
- Interceptors don't run for [WebSocket][websockets] routes.

## Classic Style

As an alternative, implement `Interceptor` with both `pre` and `post`:

<CodeFile name="lib/components/timing_interceptor.dart">

```dart
import 'package:revali_router/revali_router.dart';

class TimingInterceptor implements Interceptor {
  const TimingInterceptor();

  @override
  Future<void> pre(Context context) async {
    context.data.add(Stopwatch()..start());
  }

  @override
  Future<void> post(Context context) async {
    final watch = context.data.get<Stopwatch>();
    context.response.headers.set('X-Elapsed-Ms', '${watch?.elapsedMilliseconds}');
  }
}
```

</CodeFile>

Apply it with `@TimingInterceptor()`, or by type with `@Intercepts([TimingInterceptor])`.

[middleware]: /constructs/revali_server/lifecycle-components/advanced/middleware
[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[catchers]: /constructs/revali_server/lifecycle-components/advanced/exception-catchers
[reflect]: /constructs/revali_server/context/reflect
[websockets]: /constructs/revali_server/response/websockets
