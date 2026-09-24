---
title: Allow Origins
description: Restrict which browser origins may call your API (CORS), and how Revali answers CORS preflight requests.
---

`@AllowOrigins` limits which websites (origins) can call your API from a browser. Without it, Revali accepts every origin. Add it when your API should only be reachable from your own frontends.

## Example

<CodeFile name="routes/controllers/orders_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@AllowOrigins({'https://myapp.com', 'https://admin.myapp.com'})
@Controller('orders')
class OrdersController {
  const OrdersController();

  @Get()
  List<String> list() => ['a-1', 'b-2'];
}
```

</CodeFile>

| Request | Response |
| --- | --- |
| `Origin: https://myapp.com` | `200`, `Access-Control-Allow-Origin: https://myapp.com` |
| `Origin: https://evil.example` | `403 CORS policy does not allow access from this origin.` |
| No `Origin` header (curl, mobile apps, server-to-server) | `200`, `Access-Control-Allow-Origin: *` |

Requests without an `Origin` header are never blocked. CORS only governs browsers, so restricting origins does not lock out your non-browser clients. To change the `403` body, see [Default Responses][default-responses].

## Variants

| Annotation | Allows |
| --- | --- |
| `@AllowOrigins({...})` | These origins, plus the origins allowed by the enclosing controller |
| `@AllowOrigins.noInherit({...})` | Only these origins. The parent's origins are ignored. |
| `@AllowOrigins.all()` | Any origin. The parent's origins are ignored. |

```dart
@AllowOrigins({'https://myapp.com'})
@Controller('api')
class ApiController {
  const ApiController();

  @Get('shared') // https://myapp.com
  String shared() => 'ok';

  @AllowOrigins({'https://partner.com'}) // https://myapp.com and https://partner.com
  @Get('combined')
  String combined() => 'ok';

  @AllowOrigins.noInherit({'https://internal.myapp.com'}) // only https://internal.myapp.com
  @Get('internal')
  String internal() => 'ok';

  @AllowOrigins.all() // any origin
  @Get('public')
  String public() => 'ok';
}
```

<Callout type="caution" title="Put it on controllers or endpoints">

An `@AllowOrigins` on the `@App()` class is currently merged only into endpoints that declare their own `@AllowOrigins`. On its own it restricts nothing. Put the annotation on each controller that needs it.

</Callout>

## Matching

Each entry is compared with the request's `Origin` in three ways. It matches if it is `*`, if it equals the origin exactly, or if it matches the origin **as a regular expression**.

<Callout type="warning">

The regular expression is not anchored. `'https://myapp.com'` also matches `https://myapp.com.attacker.io`, because the pattern appears inside that string. For a strict allowlist, write anchored patterns with escaped dots:

```dart
@AllowOrigins({r'^https://myapp\.com$', r'^https://([a-z]+\.)?myapp\.com$'})
```

</Callout>

## CORS Response Headers

Every request that passes the check gets these headers, whether or not you use `@AllowOrigins`:

| Header | Value |
| --- | --- |
| `Access-Control-Allow-Origin` | The request's `Origin`, or `*` when it has none |
| `Access-Control-Allow-Credentials` | `true` |
| `Access-Control-Allow-Methods` and `Allow` | The methods the path supports, for example `OPTIONS, GET, HEAD, POST` |
| `Access-Control-Allow-Headers` | Any [`@ExpectHeaders`][expect-headers] names, plus the headers the client listed in `Access-Control-Request-Headers` |

## Preflight Requests

Browsers send an `OPTIONS` preflight before most cross-origin requests that are not "simple": for example, requests that send JSON, send a custom header, or use `PUT`, `PATCH`, or `DELETE`. Revali answers it automatically, and you don't write an `OPTIONS` endpoint:

1. The origin and header rules ([`@ExpectHeaders`][expect-headers], [`@PreventHeaders`][prevent-headers]) are checked. A failure returns `403`.
2. Otherwise the response is `200` with an empty body and the CORS headers above.

No lifecycle components run for an `OPTIONS` request. See [OPTIONS Requests][options] for more on how the allowed methods are worked out.

```bash
curl -i -X OPTIONS http://localhost:8080/api/orders \
  -H 'Origin: https://myapp.com' \
  -H 'Access-Control-Request-Method: GET'
```

```http
HTTP/1.1 200 OK
access-control-allow-origin: https://myapp.com
access-control-allow-credentials: true
access-control-allow-methods: OPTIONS, GET, HEAD
allow: OPTIONS, GET, HEAD
```

[expect-headers]: /constructs/revali_server/access-control/expect-headers
[prevent-headers]: /constructs/revali_server/access-control/prevent-headers
[options]: /constructs/revali_server/request/options-requests
[default-responses]: /revali/app-configuration/default-responses
