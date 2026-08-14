<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.3.0

### Features

- The generated server serves liveness and readiness probes. `healthRoutes` is registered alongside the `public` routes — **outside** the app prefix, so they answer on the bare paths an orchestrator is configured with rather than under `/api`. Readiness closes over the server's `InFlightRequests`, so it reports `503` as soon as a shutdown begins.
- The generated shutdown honours `AppConfig.drainDelay`, but only on `SIGTERM`. `SIGINT` is a human at a terminal who wants the process gone now; `SIGTERM` is an orchestrator, which is who the delay exists for.
- The generated shutdown reaches worker isolates. Workers are spawned with a registration port and drain on the parent's command instead of watching signals themselves, and the parent drains its own isolate concurrently with theirs before exiting — so probes report `503` across the whole fleet at once, and `exit(0)` no longer truncates requests still running in a worker. Verified against a running three-worker server: with uneven request durations, the longest request on a worker returns `200` where it previously died with no response at all.
- `routes.json` gains `returns` and `returnsNullable`, and its `version` moves to `2`. It previously carried **no return type at all**, which is why the manifest could describe a route table but not a contract.
- Add `revali routes --check <pinned.json>`, which compares the current manifest against one a consumer pinned and exits non-zero on a breaking change, so it works as a CI gate. Severity is judged from the caller's side: a removed route, a new required parameter, a parameter that became required, a changed type or location, a changed or newly-nullable return, and a changed transport all break callers; an added route, a new optional parameter and a relaxed requirement do not. A removed parameter is reported as compatible rather than breaking — the server still accepts callers that send it, it just ignores the value now. Parameters are matched on their **wire** name, so renaming a Dart argument while keeping `@Query('id')` reports nothing. Comparing against a version 1 pin says return types were not compared rather than silently treating absent as unchanged.
- `routes.json` reports return types **unwrapped**: what a caller receives is the awaited value, so `Future<String>` and `String` are the same contract. Leaving the wrapper on flagged a breaking change the moment a handler became async, and read `returnsNullable` off `Future` rather than off what is actually returned — so `Future<String?>` claimed to be non-nullable and the nullability check could never fire for an async handler.
- Generate consumer registration for methods annotated with `@Consumes(topic, group:)`. A `registerConsumers` function is emitted beside `routes`, constructing controllers the same way so a singleton controller is shared with its routes rather than rebuilt for messages. Handlers take a `BrokerMessage` or nothing; anything else is rejected at generation time, naming the method, rather than emitting code that will not compile. A method that is both a route and a consumer, or carries two `@Consumes`, is rejected for the same reason. Nothing at all is emitted when no handler is annotated — a server generated for an app without messaging is byte-identical to one generated before this existed.
- Consumers drain **before** HTTP during shutdown: they pull *new* work, so leaving them running while requests drain means the process keeps taking on messages it is about to abandon.
- Add `revali services`, which lists every Revali service in a repository — a package with a `routes/` directory that depends on the framework. The dependency check matters: `routes/` alone is a common enough directory name that a frontend router or a docs folder would otherwise be reported as a service. `--paths` prints one path per line for scripting.
- Add `revali compose`, generating a `docker-compose.yaml` for every service found. `revali_docker` produces a Dockerfile per service, which is enough to ship one and not enough to *run the system* — and starting five services by hand is the point at which people stop running the whole thing locally and start testing one service against staging, which hides exactly the mismatches that splitting into services creates. Ports are assigned sequentially from `--base-port` and passed as `PORT`, which `AppConfig.fromEnv` reads. Services that share a package name — several examples can legitimately be called `hello` — are keyed by path instead, because a duplicate compose key does not error: the later entry silently replaces the earlier one and a service vanishes from the file meant to describe it. A service with no Dockerfile yet is emitted with a comment saying so rather than omitted, since a silent absence is harder to notice than a build that fails and explains why.
- Add `revali up`, which runs every service in the repository at once. Five services is otherwise five `revali dev` processes in five terminals, which is the point at which people stop running the whole system locally and start developing one service against staging or mocks — and a system you cannot run is one you cannot trust to work deployed. Each service gets a port assigned from `--base-port` and passed as `PORT`, output is merged with a stable colour and an aligned per-service prefix, and `--only` runs a subset by name or path (an unknown name is refused rather than silently ignored, since a typo would otherwise look like a service that starts and does nothing). `Ctrl-C` sends `SIGTERM` to every child, so each drains through the graceful-shutdown path rather than being killed. A service that fails to start is reported and the rest carry on — the usual cause is a compile error the developer is about to fix, and losing the whole fleet for it makes the loop worse.
- `revali up` forwards `r` / `c` / `q` to every service. They could not simply be piped through: a child's stdin is a pipe rather than a terminal, so `revali dev` inside it takes its headless path and never reads keystrokes — the keys did nothing, while file-watching reload kept working and made reload look fine. The parent writes each service's `.revali_cmd`, which `revali dev` already watches when it has no TTY, so this reuses that channel rather than adding a second one. One file per service in its own directory: a single shared file would be read and truncated by whichever service noticed first. `q` also stops the fleet, so a child wedged badly enough to ignore its command file cannot leave `revali up` waiting forever, and the terminal is restored on the way out rather than left in raw mode.

# revali_annotations

## 3.2.0

### Features

- Add `@Consumes(topic, group:)`, marking a method as the handler for messages on a topic. `group` is required rather than defaulted: a default would have to be derived from the package or class name, and a group name that changes when code is renamed silently re-reads a stream from scratch.

# revali_construct

## 2.5.0

### Features

- Add `MetaConsumer` and `MetaRoute.consumers`, describing methods annotated with `@Consumes` so constructs can generate against them. Kept separate from `MetaMethod` rather than folded into it: a consumer has no HTTP verb, no path and no request to bind from, so every field they would share is one that does not apply.

# revali_core

## 3.1.0

### Features

- Add health probes to `AppConfig`. `HealthSettings` (exposed as `AppConfig.health`) configures a liveness path (`/healthz`) and a readiness path (`/readyz`), a list of `HealthCheck`s consulted by readiness, and a per-check `checkTimeout`. Either path can be set to `null`, or the whole thing disabled with `const HealthSettings.disabled()`.
- Liveness and readiness answer different questions, and the split is deliberate: liveness failing tells an orchestrator to **restart** the process, so it keeps returning `200` during a graceful shutdown, while readiness flips to `503`. Failing liveness mid-drain would kill exactly the in-flight requests the drain exists to protect. Liveness also runs no checks — consulting a database there turns one database blip into a restart storm.
- Add `AppConfig.drainDelay` (default `Duration.zero`, so existing behaviour is unchanged). Closing the listening socket is invisible to a load balancer: it keeps routing until its own readiness probe fails, and every request it sends in the meantime hits a closed socket. This is the window in which readiness reports `503` while the server can still serve. Behind a load balancer, set it longer than the probe's period times its failure threshold, and keep `drainDelay + shutdownTimeout` under the platform's kill grace period.
- Add `TraceContext`, ambient for the whole of a request. A request id that only exists as a header dies at the first hop — a call the handler makes to another service opens a fresh, uncorrelated request, and the two services' logs cannot be joined afterwards. `TraceContext.current` carries the request id, W3C `traceparent`/`tracestate` and a mutable `baggage` map, reachable from anywhere inside the request without being threaded through. `outboundHeaders()` produces the headers to forward. Nothing forwards them automatically: what counts as a trusted peer is the app's call, not the framework's.
- `traceparent` is **propagated, never invented**. It is carried verbatim when the caller sent one and left absent when they did not — a fabricated one is worse than none, since a collector will stitch it into the wrong trace. This deliberately stops short of span lifecycles, samplers and exporters.
- `baggage` is encoded and parsed in the W3C header format, with keys and values percent-encoded so an unescaped `,` or `=` cannot silently split one entry into two. Malformed inbound entries are skipped rather than throwing, since they arrive from another service.
- Add `Env`, a runtime reader for the process environment: `require`, `string`, `integer`, `boolean` and `uri`, each with an explicit fallback. A variable set to the empty string counts as **unset**, because orchestrators and CI routinely inject empty values for variables nobody configured. A value that is present but unparseable **throws** rather than falling back — someone set it on purpose, and quietly ignoring it is how an app ends up listening on a port nothing routes to. Takes an explicit map in tests, so a suite never mutates the real environment.
- Add `AppConfig.fromEnv`, taking host and port from the environment at startup. Two defaults differ from `AppConfig.defaultApp` deliberately: the host is `0.0.0.0` rather than `localhost`, since a server bound to loopback inside a container refuses every request from outside while looking perfectly healthy; and the port comes from `PORT`, which is how Cloud Run, Heroku, Render and Fly assign one. It is **not** `const` — it reads the environment, which is only knowable at runtime — so an app using it cannot have a `const` constructor either. That is the point: a port baked in at compile time cannot be changed by the platform running the image.
- Add `HttpError`, a failure that survives the hop. A status code alone tells a caller that something went wrong, not *what*: two different 404s are indistinguishable to the service calling you, so its only options are to give up or to match on a human-readable message that was never meant to be an API. `HttpError` carries a stable `code` alongside the status, plus a `message` for humans and optional machine-readable `details`, and serialises to `{"error": {...}}` — mirroring the `{"data": ...}` wrapper successful responses already use. Named constructors cover the usual statuses. Throwing it is **opt-in**: the framework's existing plain-text default responses are unchanged, so clients reading them today keep working.
- Add the messaging contract: `MessageBroker`, `BrokerMessage`, `BrokerSubscription` and `ConsumerRegistry`, plus an `InMemoryBroker` for tests and local development. Revali does **not** run a broker — like a database it is infrastructure you deploy, and this is the client side. Implementations live in their own packages so the framework never picks a winner between brokers whose delivery and ordering guarantees genuinely differ.
- `ConsumerRegistry` gives each message what a request already gets: its own `TraceContext`, seeded from the message headers, so an event published during a request stays on that request's trace when it is handled minutes later in another process; its own `RequestScopedDI` scope, disposed when the message ends; and a place in shutdown. Draining **pauses** subscriptions before waiting, rather than cancelling — cancelling abandons messages mid-handler, and on an at-least-once broker every one of them is then redelivered as a duplicate nobody needed.
- Add `AppConfig.createBroker()`, returning null by default. This is what makes messaging opt-in: an app that supplies no broker registers no consumers even when handlers are annotated, and the broker it does supply is drained and closed as part of shutdown.

# revali_test

## 0.1.0

### Features

- `TestHeaders.add` appends instead of overwriting, matching `dart:io`. A response setting several cookies — each needing its own `Set-Cookie` line — arrived with only the last one, so tests could not see the rest.
- `TestRequest` sends binary and streamed bodies as they are. Previously anything that was not a `String` was `jsonEncode`d, so a `List<int>` upload arrived as the *text* `"[1,2,3]"`, and a `Stream` body was read as WebSocket frames rather than a request body — leaving the request empty. WebSocket input now arrives through its own `webSocketInput` parameter, so a streamed HTTP body is expressible at all.
- First release. `revali_test` was previously `publish_to: none`, so the testing helpers the docs and the internal suite rely on were unavailable to anyone outside this repo. It exposes `TestServer`, which stands in for an `HttpServer` so a generated server runs in-process without binding a socket, plus `TestRequest`/`TestResponse`/`TestHeaders` and the `expectRecentHttpDate` matcher.

# revali_mcp

## 0.1.0

### Features

- First release. `revali_mcp` was previously `publish_to: none`, so the Cursor configuration in the repo README could not resolve for anyone outside this repo. Exposes `list_routes`, `get_route`, `doctor`, `recent_requests`, and `create_scaffold` over an MCP stdio server.

### Fixes

- Frame stdio messages by byte count rather than decoded character count. `Content-Length` counts bytes, so any message body containing a non-ASCII character left the server waiting on data that had already arrived, and it never replied. Responses are likewise written as UTF-8 bytes instead of through `stdout.write`, which re-encodes using `Stdout.encoding` and could disagree with the length already announced.

<!-- REVALI ROUTER -->

# revali_router

## 5.1.0

### Features

- Add `healthRoutes`, which builds the liveness and readiness routes described by a `HealthSettings`. Readiness takes an `isDraining` callback, read per request rather than captured, so the probe reflects the current shutdown state instead of the state at startup. Checks run concurrently, so the probe costs the slowest check rather than the sum of them, and a check that fails, throws, or outruns `checkTimeout` is reported as unhealthy with its name — a probe that 500s tells an orchestrator strictly less than one that names the dependency that is down.
- `shutdownServer` takes a `drainDelay`, applied after the drain is flagged but **before** the listening socket closes. Requests arriving in that window are served and tracked normally, since the accept loop does not refuse while draining. Defaults to `Duration.zero`, which is exactly the previous behaviour.
- Add `WorkerFleet` and `listenForDrainCommands`, the two halves of a shutdown that reaches worker isolates. With `AppConfig.workers > 1` every isolate binds the same port with `shared: true` and keeps its own in-flight set, while only the parent watches signals — so a `SIGTERM` drained one isolate and the parent's `exit(0)` truncated the rest, and a readiness probe balanced onto a worker reported ready while the parent was already draining. The parent now tells each worker to drain and waits for them to report back before exiting. A worker that dies, never registers, or hangs is bounded by a timeout rather than holding the process open.
- Install a `TraceContext` for every request, seeded from the caller's `X-Request-Id`, `traceparent`, `tracestate` and `baggage` headers and generating a request id when none was sent. It is installed on the `handleRequest` serve path — the one `handleRouterRequests` and the generated server actually use — as well as the older `handle` split, and for every request whether or not `di` is configured: an id that only exists when dependency injection happens to be set up is one a logger cannot rely on.
- `@RequestId` now stamps the id the ambient `TraceContext` carries rather than generating a second one, so the header and the context always name the same request. It still works outside a request, where there is no context.
- Forward `AppConfig.fromEnv` on this package's `AppConfig`. `revali_router` re-exports `revali_core` with `AppConfig` hidden and defines its own subclass, which is the one apps actually extend — a constructor that exists only upstream is unreachable from an app, and one that was only added there compiled in a `revali_core` unit test while every real app failed with "Superclass has no constructor named `AppConfig.fromEnv`".
- Respond to an uncaught `HttpError` with its own status and error envelope. Handled **after** the exception catchers, so an app that registered a catcher for its own `HttpError` subtype still wins — the envelope is a fallback for an unclaimed error, not an override.

# revali_redis

## 0.1.0

### Features

- A `MessageBroker` backed by **Redis Streams**, not pub/sub: Redis pub/sub is fire-and-forget, so a consumer that is restarting simply misses whatever was published — the opposite of what a work queue is for. Streams persist, and consumer groups give one delivery per group with redelivery until acknowledged.
- Speaks RESP over a socket with no third-party client, so the package has no dependency beyond `revali_core`. The decoder returns null on an incomplete reply and the connection buffers across packets, because a reply split across two packets is routine for a large `XREADGROUP` batch and decoding it as if whole desynchronises the connection rather than failing outright.
- Acknowledges only on success, and **retries** what a handler left unacknowledged. `XREADGROUP ... >` returns only messages never delivered to anyone, so an entry a handler threw on is pending and no ordinary read touches it again; each pass now scans this consumer's own pending entries and re-delivers them with `XCLAIM`, which is also what makes Redis count the delivery. Past `maxDeliveries` the entry is dead-lettered instead. None of this depends on `claimAfter` -- reclaiming is about entries another consumer abandoned, and is still opt-in, but a message failing in *this* consumer used to stop silently: never redelivered, never dead-lettered, never reported.
- Delivery is **at least once**; handlers must be idempotent. That is the broker contract, not a limitation of this implementation.
- Integration tests against a real Redis, skipped by default so a machine without one still gets a green suite. Run them with `dart test --run-skipped --tags integration`, pointing at a server with `REDIS_TEST_HOST` / `REDIS_TEST_PORT`.
- Reclaim entries a dead consumer left pending, via `claimAfter`. Redis tracks pending entries **per consumer name**, so a replica that dies mid-message strands them in a list nobody else reads — and a pod that is replaced rather than restarted never comes back to claim them. Off by default, since it changes when a message is redelivered. Set it well above the time a healthy handler takes, or a slow handler's work is taken from underneath it and processed twice.
- Dead-letter a message that keeps failing, after `maxDeliveries` (default 5), onto `<topic>.dead` with headers recording why and where it came from. Reclaiming without this turns a message that always fails into a retry storm: claimed, failed, left pending, claimed again, forever. The entry is acknowledged only *after* the copy succeeds, so a failed copy leaves it pending rather than losing it.
- Reclaiming runs only when a read came back with no fresh work, so it spends round trips on bookkeeping only when the queue is idle.
- Survive a restart of the Redis **server**, which previously killed the process. Writing to the dead socket escaped as an unhandled `SocketException` because nothing observed the socket's `done` future — write errors do not arrive on the read stream. Behind that sat two further failures: the link was never reopened, and a consumer group lost with the server was never recreated, so every later `XREADGROUP` answered `NOGROUP` while the connection looked perfectly healthy. A connection now reopens and retries once; a `RedisError` is rethrown untouched, since that is the server answering rather than the link failing, and reconnecting would swallow the `NOGROUP` the read loop needs. The group is recreated from `0` rather than `$`: the stream is gone too, so recovery races the next publish, and a message that lands before the group is back would otherwise fall *before* `$` and never be delivered to anyone — with the publish succeeding and the consumer looking fine. Recreation is backed off so a server still coming up does not get a tight `XGROUP CREATE` loop.

<!-- CONSTRUCTS -->

# revali_docker

## 1.1.0

### Features

- Automatically generate a minimal single-stage Dockerfile whenever `revali build` already compiled a native executable (via a `build:` section in `revali.yaml`), instead of the default multi-stage, compile-inside-Docker build. Supports multi-architecture images via `ARG TARGETARCH`. See [Cross-Compiling](https://www.revali.dev/constructs/revali_docker/overview#cross-compiling).

<!-- SWAGGER -->

# revali_swagger_annotations

## 1.0.0

### Features

- Initial release with `@ApiInfo`, `@ApiTag`, `@ApiSummary`, `@ApiDescription`, `@ApiResponse`, `@ApiHidden`, and `@ApiType` annotations for customizing generated OpenAPI output.

# revali_swagger

## 1.2.0

### Fixes

- Emit the spec deterministically. Paths, the operations within each path, and component schemas were written in whatever order the filesystem walk discovered controllers, so the same project produced `/complex` first on macOS and `/users` first on Linux. A spec that reorders itself per platform cannot be diffed, committed, or compared against a golden. All three are now sorted.

- Depend on `revali_annotations ^3.0.0` (previously `revali_router_annotations ^2.2.0`). The router/annotations consolidation refactor already dropped this dependency in source, but the package version was never bumped, so pub.dev's 1.0.0 stayed pinned to `revali_router_annotations`, which pulls in `revali_router_core ^2.3.0` -> `revali_core ^1.6.0`, conflicting with `revali ^3.0.0`'s `revali_core ^2.0.0` requirement.

<!-- REVALI CLIENT -->

# revali_client

## 3.0.0

### Breaking Changes

- `HttpInterceptor.onRequest` and `onResponse` return `FutureOr<HttpResponse?>` instead of `void`. Returning `null` — the common case — means "carry on"; returning a response from `onRequest` answers without sending anything, and from `onResponse` substitutes what arrived. The old signature made retries, caching and circuit breaking impossible to build **at all**, by us or by anyone else, which is why this changes now rather than after more code depends on it. Migration is mechanical: change the return type and add `return null`.
- Interceptor errors are no longer swallowed. A throwing interceptor now fails the request instead of letting it continue in whatever half-prepared state it was left in — a failed auth interceptor previously put an unauthenticated request on the wire and surfaced as a puzzling `401` from the peer rather than an error where it actually broke.

### Features

- Add `RevaliClient.timeout`. Covers reaching the far side and getting its status back, not the time spent streaming a large body afterwards — a slow download is not the same failure as a peer that never answers. Null keeps the previous unbounded behaviour, which is a poor default in a service mesh: a peer that accepts connections and never replies otherwise holds the request forever.
- Add `RetryPolicy` and `RevaliClient.retry`, **off by default**. Two rules keep it honest: only idempotent methods (`GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`), because retrying a `POST` that reached the server and failed on the way back creates the resource twice; and only transient statuses (`502`, `503`, `504`), because a `400` will say the same thing next time and retrying it just multiplies load during an incident. A request with a streamed body is never retried at all — the stream is consumed as it is sent, so a second attempt would transmit nothing. Backoff is exponential and capped, and `Retry-After` overrides it when the server sends the delta-seconds form. Retried responses are drained, so the loop does not leak a socket per attempt.
- Retry and timeout live in `RevaliClient`, above the transport, so a custom `HttpClient` gets both instead of having to reimplement them.
- `ServerException` reads the error envelope. When the peer sent one, `code`, `reason` and `details` carry it and `isStructured` is true, so a caller can branch on `e.code == 'user_not_found'` instead of pattern-matching a body. When it did not — a plain-text response, an intermediary's HTML error page, a third-party API — those are null and the raw `body` is available exactly as before. Parsing is best-effort by design: a malformed body surfaces as the HTTP failure it already is, never as a `FormatException` from the client.
- Add `HeaderInterceptor`, which computes headers per request instead of fixing them when the client is built. The motivating case is correlation: a server handling a request and calling a peer forwards its trace headers with `HeaderInterceptor(() => TraceContext.current?.outboundHeaders() ?? const {})`. It never overwrites a header the call site set explicitly. The callback is deliberately the coupling — `revali_client` runs on the web, where `dart:io` and so `revali_core` cannot follow, so a function of `Map<String, String>` connects the two without dragging a server-only dependency into a browser bundle.

### Fixes

- Build the outgoing request *after* the interceptors run, so one that rewrites the body or the encoding is reflected in what is actually sent rather than only its headers.
- Stop the error path throwing a `TypeError` instead of reading the body. `response.stream.transform(utf8.decoder)` fails when the transport hands back a `Stream<Uint8List>` — which `package:http` does — because `transform` is generic on the stream's runtime type. Only the error path decodes a body this way, and no test exercised an error response through a generated client, so every structured failure surfaced as `type 'Utf8Decoder' is not a subtype of ...` rather than as a `ServerException`. Found by the new `test_suite/constructs/revali_client/errors` package.

# revali_client_gen

## 2.5.0

### Fixes

- Raise the `revali_client` floor to `^3.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. `revali_client` 3.0.0 is a new major, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 2.4.0 behind on `^2.1.0` would make it unresolvable alongside it. Generated client packages are unaffected: `pubspec_file.dart` resolves `revali_client` by path rather than by version constraint.
