---
title: OPTIONS Requests
description: OPTIONS is answered automatically for every route with the allowed methods
---

An `OPTIONS` request asks which methods a URL supports. Browsers send one as a CORS pre-flight before many cross-origin requests. Revali answers `OPTIONS` automatically for every route; you do not declare an endpoint for it.

## Example

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController();

  @Get()
  List<String> list() => [];

  @Post()
  void create() {}
}
```

</CodeFile>

```bash
curl -i -X OPTIONS http://localhost:8080/api/users
# HTTP/1.1 200 OK
# allow: OPTIONS, GET, HEAD, POST
# access-control-allow-methods: OPTIONS, GET, HEAD, POST
# access-control-allow-origin: *
# access-control-allow-credentials: true
```

## Behavior

- The endpoint handler is not called. The response is returned right after the origin and header checks.
- `Allow` and `Access-Control-Allow-Methods` list every method registered on the path, plus `OPTIONS`, plus `HEAD` when there is a `GET`.
- `Access-Control-Allow-Origin` echoes the request's `Origin`, or `*` when there is none. Requests from origins outside [`@AllowOrigins`](/constructs/revali_server/access-control/allow-origins) get `403`.

CORS settings and pre-flight details are covered in [Access control](/constructs/revali_server/access-control/allow-origins#preflight-requests).
