# CHANGELOG

## 3.1.0 | 08.15.26

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
- Add `IsolateIdentity`, which says which isolate of the app the caller is running in — `index`, `workerCount`, and `isWorker` derived from the index rather than stored, so the two cannot disagree. With `AppConfig.workers` above 1 the same program runs several times over and nothing in it could tell the copies apart, which matters to anything that identifies itself to an external system **by name**: every isolate picks the same one. `createBroker()` is exactly that case and takes no arguments, so it could not have been handed the answer — an ambient fact is what reaches code that has no parameter to receive it, and widening that signature would have been a breaking change to every app that overrides it. Statics in Dart are per-isolate, so each isolate genuinely holds its own copy with nothing shared and no race to guard: that is not a caveat about the mechanism, it *is* the mechanism, and it is the same reason the generated server's private worker flag works. Unset it describes the parent of a single-isolate app, so a unit test or an app that never spawns workers observes something true having configured nothing, and there is no null to handle.

## 3.0.0 | 08.13.26

### Breaking Changes

- `Observer.see` takes one `ObservedRequest` instead of `(Request, Future<Response>)`. Migration is mechanical: `see(request, response)` becomes `see(observed)`, with `observed.request` and `observed.response` in place of the parameters, and `observed.summary` newly available. One interface rather than two — an observer that only wants the finished picture awaits `observed.summary` instead of implementing a second type.
- Remove the deprecated `DI` registration methods. `registerInstance<T>` and `register<T>` are gone from `DI`, `DIImpl`, `DIHandler`, and `RequestScopedDI`; use `registerSingleton<T>` and `registerFactory<T>` / `registerLazySingleton<T>` instead. The `Factory<T>` typedef is unchanged.

### Features

- Add `RequestSummary` and `ObservedRequest`, giving observers what they could not previously reach: how a request turned out. `Observer.see` now takes a single `ObservedRequest` carrying the `request` (available immediately) plus futures for the `response` and a `summary` — method, path, matched **route** path, status, duration and error. Label metrics with `routePath` (`/api/users/:id`) rather than `path` (`/api/users/42`); that is the difference between one time series and one per id. `see` also accepts a `FutureOr` return, so an observer that reports immediately need not be `async`.
- Add `CompressionSettings`, exposed as `AppConfig.compression`. Responses are gzipped by default for clients that send `Accept-Encoding: gzip`, above a 1 KB threshold and only for text-shaped mime types. Use `CompressionSettings.disabled()` when a CDN or reverse proxy already compresses.
- Add request-scoped dependencies. `DI.registerRequestScoped<T>` builds `T` once per request and shares it for the rest of that request, with nothing shared between requests — the missing middle between `registerSingleton` (whole process) and `registerFactory` (every resolution). Instances implementing the new `Disposable` interface are released when the request ends, in reverse creation order, whether it succeeded or threw. Resolving a request-scoped type outside a request throws rather than silently handing back an undisposed instance shared with nobody. `RequestScopedDI` is now a working per-request container rather than a stub: it caches what it builds, tracks it for disposal, and finds registrations through the `DIHandler` wrapper via the new `RequestScopedRegistry` interface.
- Add graceful-shutdown configuration to `AppConfig`: `handleShutdownSignals` (default `true`) to opt out of signal handling, `shutdownTimeout` (default 15s) to bound how long in-flight requests are awaited, and an `onServerStopped` hook that runs once they have drained so the app can release databases, consumers and file handles.

### Fixes

- Add `SetCookies.headerValues()`, returning one formatted `Set-Cookie` line per cookie instead of an invalid comma/semicolon-joined line (RFC 6265 §4.1.1). Published `revali_router` 4.0.2 already calls this method against the `SetCookies` interface, so any project resolving `revali_core` 2.0.0 alongside it fails to compile.
- Reflect `https` (not `http`) in the "Serving at ..." startup log line when TLS is enabled via `--cert`/`--key` or `AppConfig.secure`.

## 2.0.1 | 08.07.26

### Fixes

- Add `SetCookies.headerValues()`, returning one formatted `Set-Cookie` line per cookie instead of an invalid comma/semicolon-joined line (RFC 6265 §4.1.1). Published `revali_router` 4.0.2 already calls this method against the `SetCookies` interface, so any project resolving `revali_core` 2.0.0 alongside it fails to compile.
- Reflect `https` (not `http`) in the "Serving at ..." startup log line when TLS is enabled via `--cert`/`--key` or `AppConfig.secure`.

## 2.0.0 | 08.04.26

### Breaking Changes

- Merge `revali_router_core` into this package (that package is deprecated). `Request`, `Response`, `Guard`, `Middleware`, `Interceptor`, `ExceptionCatcher`, `Observer`, `CombineComponents`, `ResponseHandler`, `Meta`, `MetaScope`, `Reflect`, `RouteEntry`, `TrustedProxy`, `Cookies`, `Headers`, `Body`, and related types now live here.
- Move `AllowOrigins`, `PreventHeaders`, and `ExpectHeaders` here from `revali_annotations` (still re-exported from there for compatibility).

### Features

- Add `AppConfig.workers` for multi-isolate serving (`shared: true` when > 1).
- Add `AppConfig.backlog` to control the `HttpServer.bind` listen backlog.

## 1.6.0 | 06.17.26

### Features

- Add `RequestScopedDI` for request-scoped dependency injection, installable via a request wrapper and `Zone`.

## 1.5.0 | 04.28.26

### Features

- Add `runStartup` on `AppConfig` so apps can wrap async server startup (bind, DI, routes); the default implementation forwards to the provided `start` callback unchanged.

## 1.4.0 | 04.15.25

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

## 1.3.0 | 04.09.25

### Features

- Add `registerLazySingleton` and `registerFactory` methods to `DI` interface
  - This is to support `factories`, so that dependencies can be re-created each time they are resolved

### Future BREAKING Changes

- `DI.register` will be removed in favor of `registerLazySingleton` and `registerFactory`
- `DI.registerInstance` will be removed in favor of `registerSingleton`

## 1.2.0 | 01.18.25

### Enhancements

- Require `Object` type for `DI` registrations

## 1.1.0 | 12.11.24

### Features

- Abstract `DI` class to support creating own instances of `DI`
- Create `DIHandler` to override dependency registry during server startup
- Add `initializeDI` method to support creating own instances of `DI`

## 1.0.0 | 11.14.24

- Initial Release
