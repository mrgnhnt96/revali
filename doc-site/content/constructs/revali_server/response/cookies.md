---
title: Cookies
description: Read request cookies with @Cookie and set response cookies with SetCookies
---

Read a cookie the client sent with `@Cookie(name)`. Set cookies on the response through `SetCookies`, which becomes one `Set-Cookie` header per cookie.

## Minimal example

<CodeFile name="routes/controllers/session_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('session')
class SessionController {
  const SessionController();

  @Post()
  void login(SetCookies cookies) {
    cookies['session'] = 'abc123';
    cookies.maxAge = const Duration(days: 7);
  }

  @Get()
  String current(@Cookie('session') String? session) => session ?? 'none';
}
```

</CodeFile>

```bash
curl -i -X POST http://localhost:8080/api/session
# set-cookie: session=abc123; Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=604800

curl http://localhost:8080/api/session -H 'Cookie: session=abc123'
# {"data":"abc123"}
```

## Reading cookies

| Where | How |
| ----- | --- |
| Endpoint, one cookie | `@Cookie('name') String? value` (a missing cookie on a non-nullable parameter gives `400`) |
| Endpoint, all cookies | `RequestCookies cookies` parameter |
| Lifecycle component | `request.headers.cookies['name']` |

<Callout type="caution">

An unannotated `Cookies` parameter is the **response** cookies, not the request's. Use `RequestCookies` to read what the client sent.

</Callout>

## Setting cookies

`SetCookies` is available as an implied parameter in endpoints and lifecycle components, and as `response.headers.setCookies`.

```dart
class EnsureVisitorId implements LifecycleComponent {
  const EnsureVisitorId();

  MiddlewareResult assign(Request request, SetCookies cookies) {
    if (request.headers.cookies['visitor'] == null) {
      cookies['visitor'] = generateVisitorId();
    }

    return const MiddlewareResult.next();
  }
}
```

| Member | Effect | Default |
| ------ | ------ | ------- |
| `cookies['name'] = value` | Adds or replaces a cookie. | |
| `remove('name')` | Drops a cookie from this response. | |
| `maxAge` | `Max-Age` as a `Duration`. | unset (session cookie) |
| `expires` | `Expires` as a `DateTime`. | unset |
| `domain` | `Domain` | unset |
| `path` | `Path` | `/` |
| `secure` | `Secure` flag | `true` |
| `httpOnly` | `HttpOnly` flag | `true` |
| `sameSite` | `SameSiteCookie.strict`, `.lax` or `.none` | `lax` |

<Callout type="important">

Attributes are shared: every cookie set on one response gets the same `Max-Age`, `Path`, `Secure`, and so on. If two cookies need different attributes, set them on different responses.

</Callout>

To delete a cookie in the browser, set it again with `Max-Age` 0:

```dart
cookies['session'] = '';
cookies.maxAge = Duration.zero;
```

Related: [Response headers](/constructs/revali_server/response/headers) · [Binding](/constructs/revali_server/core/binding#cookie---request-cookies)
