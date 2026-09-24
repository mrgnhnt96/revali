---
title: Throttle
description: Reject callers that send too many requests with 429 Too Many Requests.
---

`@Throttle` is a built-in [guard][guards] that rejects a caller with `429 Too Many Requests` once it goes over a request allowance. Apply it to an app, a controller, or a single endpoint.

```dart
import 'package:revali_router/revali_router.dart';

@Throttle(max: 100, window: Duration(minutes: 1))
@Controller('search')
class SearchController {
  const SearchController();

  @Get()
  Future<List<Result>> search(@Query() String q) => _search(q);
}
```

| Parameter | Default | Meaning |
| --- | --- | --- |
| `max` | `60` | Requests allowed per window. Must be greater than `0`. |
| `window` | `Duration(minutes: 1)` | How long an allowance lasts |
| `bucket` | The matched route | A name for a shared allowance. See below. |

## What Counts as One Caller

A caller is identified by client IP, resolved through `AppConfig.trustedProxy`. Behind a proxy or load balancer, this counts the real client instead of the proxy that forwarded every request. See [Client IP][client-ip].

## What Counts as One Allowance

By default, each **matched route** has its own allowance, keyed by its registered path rather than the concrete URL. `/api/users/:id` is one bucket, so a caller hitting `/api/users/1` and `/api/users/2` spends one allowance, not two.

Set `bucket` to share one allowance across several endpoints. This is usually what you want for something like sign-in:

```dart
@Throttle(max: 5, window: Duration(minutes: 15), bucket: 'auth')
@Post('login')
Future<Session> login(@Body() Credentials body) => _login(body);

@Throttle(max: 5, window: Duration(minutes: 15), bucket: 'auth')
@Post('reset-password')
Future<void> reset(@Body() Email body) => _reset(body);
```

## The Rejection

A blocked request gets `429` with the body `Too Many Requests` and these headers:

| Header | Meaning |
| --- | --- |
| `Retry-After` | Seconds until the allowance resets. Never `0`. |
| `X-RateLimit-Limit` | The configured `max` |
| `X-RateLimit-Remaining` | `0`, since the caller is over the limit |

Throttle is a guard, so it runs after all middleware, and the response follows the usual [error response][error-responses] rules.

## Limits

<Callout type="caution">

**It is a fixed window.** A caller can send up to `2 × max` requests across a window boundary: `max` at the end of one window and `max` at the start of the next. Choose `max` with that in mind, or use a proxy-level limiter if you need a strict sliding window.

**State is kept in memory, per process.** With `AppConfig.workers > 1`, or more than one instance behind a load balancer, each process has its own counters, so the effective limit is multiplied by the number of processes. For a limit shared across instances, enforce it in front of the server or back it with an external store such as Redis.

</Callout>

[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[client-ip]: /constructs/revali_server/request/client-ip
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
