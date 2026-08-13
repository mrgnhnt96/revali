# Microservices support — plan

> Source: `todo.md` → "Think of ways to better support micro services".
> This file is the worked-out version of that item. It is a **plan**, not a
> record of shipped work — nothing below is implemented unless it says so.

Everything here is framed around **one hop**: what happens when service A
calls service B. That framing is deliberate. Revali is already a competent
single service; almost every gap only becomes visible at the boundary between
two of them.

---

## What already lands

Worth stating plainly, because it is more than it looks like and it changes
what still needs building.

| Capability | Where | Microservice relevance |
|---|---|---|
| Graceful shutdown | `packages/revali_core/lib/app_config/app_config.dart:81-99`, `revali_router/lib/src/server/graceful_shutdown.dart` | `SIGTERM` drain is what container platforms require on every deploy and scale-down |
| In-flight tracking | `revali_router/lib/src/server/in_flight_requests.dart` | The drain set a readiness probe would need to consult |
| `Observer` / `RequestSummary` | `packages/revali_core/lib/components/observer.dart` | Exposes `routePath` (`/api/users/:id`) not the concrete path — the difference between one time series and one per id |
| `revali_client` | `constructs/revali_client/` | Generates a **whole client package**, pubspec included (`client_construct.dart:34`), with a runtime-overridable `baseUrl`. The strongest asset here by a wide margin |
| `revali_docker` | `constructs/revali_docker/` | Multi-stage production Dockerfile |
| Request-scoped DI in a zone | `revali_router/lib/src/router/router.dart:259-270` | The mechanism gap #1 needs, already built and already installed per request |
| `@RequestId()` | `revali_router/lib/src/kits/request_id.dart` | Inbound half of correlation |
| Flavors | `@App(flavor: '...')` | Per-environment `AppConfig` |
| `workers` / `backlog` | `AppConfig` | Horizontal scale within one process |

The consequence: this is not a from-scratch effort. Most items below are
**connective tissue between things that already exist**, which is why they are
small.

---

## Gap 1 — Context dies at the hop

**Status: SHIPPED.** `revali_core` 3.1.0, `revali_router` 5.1.0,
`revali_client` 2.2.0. What landed:

- `TraceContext` in `revali_core` — ambient for the whole request, carrying the
  request id, W3C `traceparent`/`tracestate` and a mutable `baggage` map.
  `outboundHeaders()` produces what to forward.
- `Router` installs one per request, seeded from the caller's headers.
- `@RequestId` stamps the id the context carries instead of generating a
  second one.
- `HeaderInterceptor` in `revali_client` bridges to outbound calls.
- 19 unit tests in `revali_core`, 14 in `revali_router` (including a real
  two-service hop), 5 in `revali_client`.

**Decisions taken, against the open question below:** `traceparent` is
propagated verbatim and never invented, with no span lifecycle — the option
argued for at the bottom of this section. Forwarding is never automatic:
`outboundHeaders()` is one line the app writes, because what counts as a
trusted peer is the app's call. Auth forwarding was not built at all.

**A bug this nearly shipped with.** The zone was first installed in
`Router.handle`, which is the *older* split path. `handleRouterRequests` — what
the generated server actually uses — goes through `Router.handleRequest`, so
the context would have been null in every real app while every unit test
passed. The end-to-end test caught it. It is now installed on both paths,
inside `_handleRequest` where the request headers first exist.

**Constraint worth recording:** `revali_client` depends only on `http` and runs
on the web, where `dart:io` — and therefore `revali_core` — cannot follow. The
trace type cannot be imported there, which is why the bridge is a
`Map<String, String> Function()` callback rather than a direct dependency.

**Original analysis follows.**

**Priority: highest. Nothing else on this list is worth as much.**

### Evidence

`@RequestId()` stamps an inbound header and stops:

```dart
// revali_router/lib/src/kits/request_id.dart
InterceptorPreResult ensureId(Headers headers) {
  final existing = headers[headerName];
  if (existing == null || existing.isEmpty) {
    headers.set(headerName, _generateId());
  }
}
```

Nothing carries that value outbound. A generated client call made from inside
a handler opens a fresh, uncorrelated request. Two services, two disjoint sets
of logs, no way to join them.

### Why it is cheap

The hard part is already done. `Router` installs a `RequestScopedDI` into a
zone for the entire request pipeline:

```dart
// revali_router/lib/src/router/router.dart:259
final scope = RequestScopedDI(parent: parent);
return runZoned(
  ...,
  zoneValues: {RequestScopedDI.zoneKey: scope},
);
```

An ambient outbound context rides the same zone.

### Sketch

1. `RequestContext.current` in `revali_core` — a zone-value holder populated by
   `Router` alongside the DI scope, carrying the inbound request id,
   `traceparent`, and a caller-extensible bag.
2. A default `HttpInterceptor` in `revali_client` that reads it and stamps
   outgoing headers. Opt-out per client, since not every outbound call should
   leak inbound headers.
3. Auth forwarding as **explicit opt-in**, never default — forwarding a caller's
   bearer token to an arbitrary third-party host is a credential leak, and the
   client has no way to know whether the target is a trusted peer.

### Open question

Whether to model this as W3C Trace Context (`traceparent` / `tracestate`)
from the start. Argument for: it is what every collector already understands
and there is no migration cost later. Argument against: it implies span
lifecycle management, which is a much larger surface than a correlation id.
**Leaning: carry `traceparent` verbatim when present, generate a plain request
id when not.** Propagation without span creation gets most of the value at a
fraction of the size, and does not foreclose the fuller thing.

---

## Gap 2 — No health or readiness, and a shutdown ordering bug

**Status: SHIPPED.** `revali_core` 3.1.0, `revali_router` 5.1.0, `revali` 3.3.0
in `LATEST_CHANGELOG.md` (not yet published). What landed:

- `HealthCheck` / `HealthCheckResult` / `HealthSettings` in `revali_core`,
  exposed as `AppConfig.health`. Liveness on `/healthz`, readiness on
  `/readyz`, both outside the app prefix.
- `healthRoutes()` in `revali_router`, wired into the generated server next to
  the `public` routes. Readiness reads the drain flag per request.
- `AppConfig.drainDelay` + `shutdownServer(drainDelay:)`, applied after the
  drain is flagged but before the socket closes, and only on `SIGTERM`.
- 13 tests in `health_routes_test.dart`, 3 in `graceful_shutdown_test.dart`.
  The ordering test was confirmed non-vacuous: with the delay forced to zero
  it fails on the first probe, the socket already unbound. Verified end to end
  against a generated app — `/healthz` and `/readyz` return plain JSON while
  `/api/hello` keeps its `{"data": ...}` wrapper.

### Probes under `workers > 1` — **also SHIPPED** (was phase 1a)

Every isolate runs `createServer` and builds **its own** `InFlightRequests`,
while `server_file_maker.dart` gated signal handling on `!isWorker`. So on
`SIGTERM` the parent flagged its drain and reported `503`, but a probe balanced
onto a worker still answered `200` — and the parent's `exit(0)` then took the
workers' in-flight requests with it.

Fixed with `WorkerFleet` / `listenForDrainCommands` in `revali_router`. Workers
are spawned with a registration port and drain on the parent's command rather
than watching signals themselves; the parent drains its own isolate
concurrently and only exits once every worker has reported back. A worker that
dies, never registers, or hangs is bounded by a timeout instead of holding the
process open. 6 tests against real spawned isolates.

Verified against a running three-worker server — and the first attempt at that
verification was **not** discriminating. With every request taking the same 3s,
the workers finished naturally before the parent's own drain ended, so the
broken build passed too. Re-run with uneven durations (500ms–14s) the
difference is unambiguous: the 14s request on a worker returns `200` with the
fix, and `http=000` — connection killed, no response — without it.

**Original analysis follows.**

### Evidence

There is no health-check support anywhere in the framework. The only `/health`
in the entire repo is hand-written in a docs example:

```
doc-site/content/constructs/revali_docker/deploy/fly-io.md:498:@Get('/health')
```

### The subtle part

This is not just a missing convenience endpoint. **Readiness must begin failing
before the drain starts**, so load balancers stop routing while `shutdownTimeout`
plays out. Today the sequence is:

```dart
// revali_router/lib/src/server/graceful_shutdown.dart:34
inFlight.beginDraining();
unawaited(server.close().catchError((Object _) {}));
final drained = await inFlight.drain(timeout);
```

`server.close()` ends the accept loop, so a *direct* connection is refused —
but a service behind a load balancer or a Kubernetes Service keeps being sent
traffic until its readiness probe fails, and there is no readiness probe to
fail. The graceful shutdown is doing real work and then getting undercut at
the routing layer.

### Sketch

1. A `HealthCheck` interface plus a registry on `AppConfig`.
2. Liveness (process is alive) and readiness (dependencies are reachable)
   served as distinct endpoints, **outside the `/api` prefix** — orchestrators
   expect bare paths, and a prefix is an app-level routing concern that a probe
   should not inherit.
3. Readiness flips to 503 the moment `inFlight.beginDraining()` is called.
4. Wire in `packages/revali/lib/server/makers/server_file_maker.dart:284`,
   where `listenForShutdown` is already generated.

### Effort

Small. The state it needs to read already exists on `InFlightRequests`.

---

## Gap 3 — Config cannot come from the environment

### Evidence

`AppConfig` requires const `host` and `port`:

```dart
// packages/revali_core/lib/app_config/app_config.dart:11
const AppConfig({
  required this.host,
  required this.port,
  ...
```

And the guidance shipped to agents is essentially *roll your own*:

```
packages/revali/lib/clis/revali_runner/commands/ai/ai_templates.dart:458
| **Env vars** | `.env`/`--dart-define` values are compile-time
  (`String.fromEnvironment(...)`); OS-level vars are runtime
  (`Platform.environment[...]`). |
```

Cloud Run, Heroku and Fly **mandate** binding the port they hand you via
`$PORT`. Every Revali service deployed to one of them has hand-written the
same snippet.

### Sketch

- `AppConfig.fromEnv()` — `host: '0.0.0.0'`, `port: $PORT` with a fallback.
  `0.0.0.0` matters: the `defaultApp()` constructor uses `localhost`, which is
  unreachable from outside a container.
- Typed binding for peer service URLs, so `baseUrl` overrides stop being
  stringly-typed plumbing at every call site.

### Effort

Small, but it is an API-surface decision — a named constructor that reads
ambient process state is a departure from the current all-const design, and
worth a deliberate yes rather than a drive-by one.

---

## Gap 4 — No resilience in the generated client

**Status: SHIPPED.** `revali_client` 3.0.0 (breaking), `revali_client_gen`
2.5.0. What landed:

- `HttpInterceptor` returns `FutureOr<HttpResponse?>` on both hooks — `null`
  to continue, a response to short-circuit or substitute. This was the
  blocker: the old `void` signature made retries, caching and circuit
  breaking impossible to build at all, by us or by anyone else.
- Interceptor errors propagate instead of being swallowed.
- `RevaliClient.timeout` and `RevaliClient.retry`, both above the transport so
  a custom `HttpClient` gets them rather than reimplementing them.
- `RetryPolicy`, off by default, restricted to idempotent methods and
  transient statuses, refusing streamed bodies outright, with capped
  exponential backoff and `Retry-After` support.
- The outgoing request is now built *after* interceptors run, so one that
  rewrites the body is reflected in what is sent.
- 13 tests for the policy, 12 for client behaviour, 5 for `HeaderInterceptor`.

**The blast radius was small and that is why it happened now.** Only
`HeaderInterceptor` implemented the interface in-repo — the `interceptors` in
`revali_client_gen` are server-side lifecycle components, unrelated. Generated
client packages are unaffected, since `pubspec_file.dart` resolves
`revali_client` by path rather than by version.

**Deliberately not built:** circuit breaking. It needs shared state across
calls and a policy for when to re-close, which is a larger design than a retry
loop, and the interceptor signature now makes it buildable outside the
framework.

**Original analysis follows.**

### Evidence

`HttpPackageClient.send` has no timeout, no retry, and no deadline propagation.
Two structural problems block adding them:

**Interceptor errors are swallowed.**

```dart
// constructs/revali_client/lib/src/integrations/http_package_client.dart:26
for (final HttpInterceptor(:onRequest) in interceptors) {
  try {
    switch (onRequest(request)) {
      case final Future<void> fn:
        await fn;
    }
  } catch (e) {
    // swallow
  }
}
```

A failing auth interceptor does not raise — it sends the request
unauthenticated and surfaces as a confusing 401 from the peer.

**Interceptors return `void`.**

```dart
// constructs/revali_client/lib/src/http_interceptor.dart
abstract interface class HttpInterceptor {
  FutureOr<void> onRequest(HttpRequest request);
  FutureOr<void> onResponse(HttpResponse response);
}
```

An interceptor can mutate headers but cannot short-circuit, substitute a
response, or trigger a retry. Retries, circuit breaking and caching are all
unbuildable against this signature — by users *or* by us.

### Sketch

1. Change the signature so `onRequest` may return a response (short-circuit)
   and `onResponse` may return a replacement. **This is breaking**, which is
   the argument for doing it early rather than late.
2. Stop swallowing interceptor errors; let them propagate as a client-side
   failure.
3. Per-client and per-call timeouts.
4. Retry with backoff, defaulting to idempotent methods only — automatically
   retrying a `POST` duplicates writes.

### Effort

Medium, and breaking. Sequence it before `revali_client` accumulates more
external users.

---

## Gap 5 — Contract drift is undetectable

### Evidence

The client is generated *for* the service that owns the routes. `ServerClient`
emits an interface, an implementation and a pubspec (`client_construct.dart:34`),
all from the local `MetaServer`. Consuming a *peer's* API therefore means
depending on generated output produced in another repo, with nothing pinning
the contract or detecting when the producer changes it.

This is the difference between "generates a client" and "supports
microservices". Today it is the former.

### Sketch

- `revali routes --json` already emits a route manifest (`.revali/server/routes.json`).
  Teach the client construct to generate **from a manifest** rather than only
  from local source.
- A consumer pins the manifest it built against.
- A CI check verifies the producer's current manifest still satisfies every
  pinned consumer contract — the check is what turns generation into a
  guarantee.

### Open question

Manifest completeness is unverified. `routes.json` is currently a routes
listing; whether it carries enough type information to generate a client
without the originating source is **not yet established and must be checked
before committing to this design.** If it does not, the choice is between
enriching the manifest and publishing generated client packages to a registry
instead.

---

## Gap 6 — Errors do not survive the hop

`ServerException` carries a status code and a raw body string. Server-side
exception catchers produce structured, typed failures; one hop away they are
an unparsed `String`. A shared error envelope plus generated typed exceptions
would let a caller `catch` a peer's domain error instead of pattern-matching
on a body.

Depends on #5 — the contract has to be shared before the error types can be.

---

## Gap 7 — Multi-service repo ergonomics

Five services means five packages and five `revali dev` processes with no
shared status board. `revali_docker` emits one Dockerfile per app and no
compose file. Neither blocks anything; both are friction that scales linearly
with service count.

---

## Gap 8 — HTTP and WebSocket only

No first-class async messaging (queue/topic consumers as a lifecycle concern),
which is how a large share of real microservice systems actually communicate.
Best shaped as a **construct**, not core — it does not belong in the request
pipeline and the broker landscape is too varied to pick a winner in the
framework.

---

## Proposed order

| Phase | Items | Rationale |
|---|---|---|
| **1** | ~~Gap 2 (health/readiness)~~ **done**, ~~Gap 1 (context propagation)~~ **done** | Both are small, both depend only on machinery that already exists, and neither can be bolted on from user code. Gap 2 additionally fixed a real ordering defect in a feature already shipped |
| **1a** | ~~Broadcast shutdown to worker isolates~~ **done** | Fallout from Gap 2: readiness and `drainDelay` were per-isolate. Closed, so both now hold at any `workers` count |
| **2** | ~~Gap 4 (client resilience)~~ **done** | Breaking signature change — done early, while `HeaderInterceptor` was the only in-repo implementer |
| **3** | Gap 3 (env config) | Small, but an API-surface decision worth taking deliberately |
| **4** | Gap 5 → Gap 6 (contracts, then typed errors) | Largest surface; Gap 6 depends on Gap 5. Gate on verifying `routes.json` completeness first |
| **5** | Gap 7, Gap 8 | Friction and reach, not correctness |

Phase 1 is the one that changes whether Revali can honestly claim microservice
support. Everything after it is refinement.

---

## What this plan does not cover

Stated so the silence is not read as a verdict:

- **Service discovery and mesh integration.** Assumed to be the platform's job
  (Kubernetes DNS, Consul, a mesh sidecar) rather than the framework's. If that
  assumption is wrong, it is a gap and it is not on this list.
- **gRPC.** Mentioned as a possible construct in `doc-site/content/constructs/index.md:108`;
  deliberately out of scope here.
- **Multi-tenancy, rate limiting, and API-gateway concerns.**
- **Whether any of this matches what Revali users actually hit in production.**
  Every gap above was derived by reading the source, not from user reports. That
  makes the list accurate about the code and unvalidated about the priorities.
