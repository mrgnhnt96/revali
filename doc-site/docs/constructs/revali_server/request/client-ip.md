---
title: Client IP
sidebar_position: 1
description: Resolve the client IP from the connection or trusted proxy headers
---

# Client IP

Revali exposes the client IP on every request via `request.ip`. You can inject it into endpoints with `@Ip`, or read it from the `Request` object in lifecycle components.

By default, the IP comes from the TCP connection's remote address. When your app runs behind a reverse proxy (load balancer, CDN, ingress), override `trustedProxy` on your app configuration so `request.ip` is resolved from proxy headers instead.

## `@Ip()` - Endpoint Binding

Inject the resolved client IP into an endpoint parameter:

```dart
@Controller('analytics')
class AnalyticsController {
  @Post('event')
  String trackEvent(
    @Body() AnalyticsEvent event,
    @Ip() String? clientIp,
  ) {
    return 'Tracked ${event.name} from $clientIp';
  }
}
```

The value is the same as `request.ip` for that request. It is `null` when no address can be determined.

Use `@Ip.pipe(MyPipe)` when you need to transform or validate the IP with a [pipe](../core/pipes.md).

## Accessing via `Request`

```dart
@Get('debug')
String debug(Request request) {
  return 'Client IP: ${request.ip}';
}
```

In lifecycle components:

```dart
final ip = context.request.ip;
```

:::tip
Prefer `@Ip()` in endpoints over passing `Request` only for the IP — it keeps handlers focused and easier to test. See [binding](../core/binding.md#ip---client-ip) for details.
:::

## Trusted Proxy Configuration

Configure which headers to trust in your app class by overriding `trustedProxy`:

```dart title="routes/main_app.dart"
@App()
class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);

  @override
  TrustedProxy get trustedProxy => const TrustedProxy(
    headers: ['X-Forwarded-For'],
  );
}
```

Common header names:

| Header | Typical source |
| ------ | -------------- |
| `X-Forwarded-For` | nginx, HAProxy, many load balancers |
| `X-Real-IP` | nginx |
| `CF-Connecting-IP` | Cloudflare |

Headers are checked in list order. The first header that yields a valid IP wins.

### Default: rightmost IP

With the default settings, each comma-separated value is scanned from **right to left**. The rightmost valid IP is the one your proxy appended — the client as seen by the proxy chain.

```dart
// X-Forwarded-For: 203.0.113.1, 198.51.100.178
// request.ip → 198.51.100.178
const TrustedProxy(headers: ['X-Forwarded-For']);
```

### Leftmost IP

If your deployment expects the original client at the **left** of the list, set `useLeftmostIp`:

```dart
@override
TrustedProxy get trustedProxy => const TrustedProxy(
  headers: ['X-Forwarded-For'],
  useLeftmostIp: true,
);
```

```dart
// X-Forwarded-For: 203.0.113.1, 198.51.100.178
// request.ip → 203.0.113.1
```

### No trusted headers

When `headers` is empty (the default), proxy headers are **ignored** and only the TCP remote address is used. This is the safe default when the app is reached directly by clients.

```dart
// X-Forwarded-For present but ignored
const TrustedProxy(); // same as TrustedProxy(headers: [])
```

### Duplicate header lines

If a header appears more than once, only the **last** line is used (matching typical proxy behavior).

## Security

Only enable `trustedProxy` when **all** traffic reaches your app through proxies you control. Otherwise clients can send `X-Forwarded-For` (or similar) and spoof `request.ip`.

For sensitive routes, combine trusted-proxy configuration with [`@PreventHeaders`](../access-control/prevent-headers.md) so clients cannot send forwarding headers themselves:

```dart
@PreventHeaders({'X-Forwarded-For', 'X-Real-IP', 'X-Original-IP'})
@Controller('admin')
class AdminController {
  @Get('audit')
  String auditLog(@Ip() String? ip) {
    return 'Action from $ip';
  }
}
```

## What's Next?

- **[Binding](../core/binding.md)** — All request data annotations including `@Ip`
- **[Prevent Headers](../access-control/prevent-headers.md)** — Block spoofed proxy headers from clients
- **[App Configuration](/revali/app-configuration/create-an-app)** — Where to override `trustedProxy`
