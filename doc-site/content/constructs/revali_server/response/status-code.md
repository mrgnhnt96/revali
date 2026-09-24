---
title: Status Code
description: The status codes Revali sends by default and how to set your own
---

Successful endpoints respond `200` unless you say otherwise. Set a fixed code with `@StatusCode(code)` on the endpoint, a computed one with `response.statusCode` in a lifecycle component, or an error code by throwing `HttpError`.

## Minimal example

<CodeFile name="routes/controllers/jobs_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('jobs')
class JobsController {
  const JobsController();

  @StatusCode(202)
  @Post()
  Map<String, dynamic> start() => {'id': 'job-1'};
}
```

</CodeFile>

```bash
curl -i -X POST http://localhost:8080/api/jobs
# HTTP/1.1 202 Accepted
# {"data":{"id":"job-1"}}
```

## Default status codes

| Situation | Status |
| --------- | ------ |
| Endpoint returned normally | `200` |
| No route matches the path and method | `404` |
| Binding failed (`MissingArgumentException`) | `400` |
| Middleware returned `MiddlewareResult.stop()` without a status | `400` |
| Guard returned `GuardResult.block()` without a status | `403` |
| Origin not allowed, or a prevented / missing expected header ([access control](/constructs/revali_server/access-control/allow-origins)) | `403` |
| `HttpError` thrown | its `statusCode` |
| Any other uncaught exception | `500` |
| [`@Redirect`](/constructs/revali_server/request/redirect) | `301` unless set |

## Setting the status

| Method | Use when |
| ------ | -------- |
| `@StatusCode(201)` on the endpoint method | The code is fixed for that endpoint. Endpoint methods only. |
| `response.statusCode = 201` in a lifecycle component (or an endpoint taking `Response`) | The code depends on runtime data. |
| `throw HttpError(...)` | Ending the request with an error. See [Error responses](/revali/app-configuration/default-responses#httperror). |
| `MiddlewareResult.stop(statusCode: 401)`, `GuardResult.block(statusCode: 401)` | Rejecting a request from middleware or a guard. |

Setting the status from a post-interceptor, which runs after the handler:

```dart
import 'package:revali_router/revali_router.dart';

class EmptyIsNotFound implements LifecycleComponent {
  const EmptyIsNotFound();

  InterceptorPostResult check(Response response) {
    if (response.body.data case {'data': null}) {
      response.statusCode = 404;
    }
  }
}
```

For `204` and `304`, Revali removes the content headers; pair `@StatusCode(204)` with a `void` endpoint.
