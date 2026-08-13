---
title: Throttle
description: Reject callers that send too many requests
---

`@Throttle` rejects a caller that exceeds a request allowance with `429 Too
Many Requests`. Apply it to an app, a controller, or a single endpoint:

```dart
@Throttle(max: 100, window: Duration(minutes: 1))
@Controller('search')
class SearchController {
  const SearchController();

  @Get()
  Future<List<Result>> search(@Query() String q) => _search(q);
}
```

## What counts as one caller

The client IP, resolved through `AppConfig.trustedProxy` — so behind a proxy
or load balancer it counts the real client rather than the proxy that
forwarded every request.

## What counts as one allowance

By default, the **matched route** — its registered path, not the concrete
URL. `/api/users/:id` is one bucket, so a caller hitting `/api/users/1` and
`/api/users/2` spends one allowance, not two.

Set `bucket` to pool several endpoints under a shared allowance, which is what
you usually want for something like sign-in:

```dart
@Throttle(max: 5, window: Duration(minutes: 15), bucket: 'auth')
@Post('login')
Future<Session> login(@Body() Credentials body) => _login(body);

@Throttle(max: 5, window: Duration(minutes: 15), bucket: 'auth')
@Post('reset-password')
Future<void> reset(@Body() Email body) => _reset(body);
```

## The rejection

A blocked request gets `429` with:

| Header | Meaning |
| --- | --- |
| `Retry-After` | Seconds until the allowance resets. Never `0` |
| `X-RateLimit-Limit` | The configured `max` |
| `X-RateLimit-Remaining` | `0`, since the caller is over |

## Two limits worth knowing before you rely on it

<Callout type="caution">

**It is a fixed window.** A caller can send up to `2 × max` across a window
boundary — `max` at the end of one window and `max` at the start of the next.
Choose `max` with that in mind, or reach for a proxy-level limiter if you need
a strict sliding window.

**State is per process.** Counters live in memory, so with
`AppConfig.workers > 1`, or more than one instance behind a load balancer,
each has its own and the effective limit multiplies by the number of
processes. For a limit shared across instances, enforce it in front of the
server or back it with an external store such as Redis.

</Callout>

## What's next?

- [Lifecycle Components](/constructs/revali_server/lifecycle-components) — how kits are applied and ordered
- [Client IP](/constructs/revali_server/request/client-ip) — configuring `trustedProxy` so the right caller is counted
