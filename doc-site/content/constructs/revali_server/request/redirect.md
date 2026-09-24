---
title: Redirect
description: Redirect an endpoint to another URL with @Redirect
---

`@Redirect(location, [code])` on an endpoint makes Revali answer with a redirect instead of running the handler. Use it for moved or aliased routes.

## Minimal example

<CodeFile name="routes/controllers/users_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class UsersController {
  const UsersController();

  @Redirect('/api/users/all')
  @Get()
  void users() {}

  @Get('all')
  List<String> all() => ['alice', 'bob'];
}
```

</CodeFile>

```bash
curl -i http://localhost:8080/api/users
# HTTP/1.1 301 Moved Permanently
# location: /api/users/all
```

## Behavior

| Detail | Value |
| ------ | ----- |
| Status code | `301` by default. Pass a second argument for another code: `@Redirect('/api/users/all', 302)`. |
| `Location` header | The first argument, sent **verbatim**. Revali does not add the app prefix or the controller path. |
| Handler | Not called. Guards, middleware and interceptors do not run either; the redirect is answered right after CORS checks. |
| Where | Endpoint methods only, at most one `@Redirect` per method. The method still needs an HTTP method annotation. |

Because the location is sent as-is:

- Use an absolute path that includes the app prefix: `/api/users/all`, not `all` or `/users/all`.
- A relative value like `'all'` is resolved by the client against the current URL, so from `/api/users` it points to `/api/all`.
- A full URL (`https://example.com/users`) redirects to another host.

Use `302`/`307` for temporary redirects; browsers cache `301` responses.
