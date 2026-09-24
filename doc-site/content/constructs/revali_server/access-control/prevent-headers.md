---
title: Prevent Headers
description: Reject requests that carry specific headers with 403, before any lifecycle component runs.
---

`@PreventHeaders` rejects a request with `403` if it carries any of the listed headers. The check runs with the other [access-control checks][lifecycle-order], before any middleware or guard. Use it to refuse headers that clients should never send to a route, such as internal debugging headers or forwarding headers on routes that sit behind a [trusted proxy][client-ip].

## Example

<CodeFile name="routes/controllers/admin_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@PreventHeaders({'x-debug', 'x-internal-token'})
@Controller('admin')
class AdminController {
  const AdminController();

  @Get()
  String index() => 'admin';
}
```

</CodeFile>

| Request | Response |
| --- | --- |
| Neither header present | `200 {"data":"admin"}` |
| `x-debug: 1` | `403 CORS policy does not allow access with these headers.` |

To change the `403` body, see [Default Responses][default-responses].

<Callout type="important" title="Write header names in lowercase">

Unlike `@ExpectHeaders`, this comparison is case-sensitive. Dart's HTTP server delivers incoming header names in lowercase, so list them in lowercase (`'x-debug'`, not `'X-Debug'`) or they will never match. `TestServer` keeps header names exactly as you pass them, so send them in lowercase in tests too.

</Callout>

## Variants and Scoping

`@PreventHeaders` can go on a controller or an endpoint, and the lists combine from the outside in.

| Annotation | Blocks |
| --- | --- |
| `@PreventHeaders({...})` | These headers, plus the headers blocked by the enclosing controller |
| `@PreventHeaders.noInherit({...})` | Only these headers. The parent's list is ignored. |

```dart
@PreventHeaders({'x-parent'})
@Controller('things')
class ThingsController {
  const ThingsController();

  @Get('inherited') // blocks x-parent
  String inherited() => 'ok';

  @PreventHeaders({'x-mine'}) // blocks x-parent and x-mine
  @Get('combined')
  String combined() => 'ok';

  @PreventHeaders.noInherit({'x-mine'}) // blocks only x-mine
  @Get('not-inherited')
  String notInherited() => 'ok';
}
```

As with [`@AllowOrigins`][allow-origins-app], a `@PreventHeaders` on the `@App()` class is currently merged only into endpoints that declare their own `@PreventHeaders`. Put it on controllers instead.

[lifecycle-order]: /constructs/revali_server/lifecycle-components#lifecycle-order
[client-ip]: /constructs/revali_server/request/client-ip
[default-responses]: /revali/app-configuration/default-responses
[allow-origins-app]: /constructs/revali_server/access-control/allow-origins#variants
