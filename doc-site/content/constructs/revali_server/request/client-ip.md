---
title: Client IP
description: Read the client IP with @Ip() or request.ip, and resolve it from trusted proxy headers
---

Every request exposes the client IP as `request.ip`. By default it is the TCP remote address. When the app runs behind a reverse proxy (load balancer, CDN, ingress), override `trustedProxy` on your app so the IP is read from a proxy header such as `X-Forwarded-For` instead.

## Minimal example

<CodeFile name="routes/controllers/whoami_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('whoami')
class WhoamiController {
  const WhoamiController();

  @Get()
  String? ip(@Ip() String? clientIp) => clientIp;
}
```

</CodeFile>

```bash
curl http://localhost:8080/api/whoami
# {"data":"127.0.0.1"}
```

| Where | How |
| ----- | --- |
| Endpoint | `@Ip() String? ip`, or `@Ip.pipe(MyPipe)` to transform it with a [pipe](/constructs/revali_server/core/pipes) |
| Lifecycle component / `Request` | `request.ip` or `context.request.ip` |

The value is `null` when no address can be determined.

## Trusted proxy

Override `trustedProxy` in your [app](/revali/app-configuration/create-an-app):

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';

@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  TrustedProxy get trustedProxy => const TrustedProxy(
        headers: ['X-Forwarded-For'],
      );
}
```

</CodeFile>

| `TrustedProxy` option | Default | Behavior |
| --------------------- | ------- | -------- |
| `headers` | `[]` | Header names to check, in order. The first header that yields a valid IP wins. Empty means proxy headers are ignored and the TCP address is used. |
| `useLeftmostIp` | `false` | `false`: take the **rightmost** valid IP in the comma-separated list (the one your proxy appended). `true`: take the leftmost. |

Resolution details:

- If a header is sent more than once, only the **last** line is used.
- Ports are stripped (`203.0.113.1:5000` and `[2001:db8::1]:443` both work). Values that are not IPs are skipped.
- If no configured header yields an IP, the TCP remote address is used.

| `X-Forwarded-For` | `useLeftmostIp: false` | `useLeftmostIp: true` |
| ----------------- | ---------------------- | --------------------- |
| `203.0.113.1, 198.51.100.178` | `198.51.100.178` | `203.0.113.1` |

Common headers: `X-Forwarded-For` (nginx, HAProxy, most load balancers), `X-Real-IP` (nginx), `CF-Connecting-IP` (Cloudflare).

## Security

Only configure `trustedProxy` when **all** traffic reaches the app through proxies you control. Otherwise a client can send `X-Forwarded-For` itself and choose its own `request.ip`.

A proxy header is only trustworthy if your proxy **overwrites** it (or appends to it, with `useLeftmostIp: false`). If the proxy passes a header through untouched, do not list it in `headers`.

[`@PreventHeaders`](/constructs/revali_server/access-control/prevent-headers) rejects any request that carries the named headers, including headers your own proxy adds. Use it to block forwarding headers only on apps or routes that are reached directly, without a proxy.

The same IP is used by [`@Throttle`](/constructs/revali_server/lifecycle-components/kits/throttle).
