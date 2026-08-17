# CHANGELOG

## 5.1.1 | 08.17.26

### Fixes

- **A `5xx` an application wrote on purpose was discarded in a released build.** Every deliberate-refusal path — an `ExceptionCatcher` returning `.handled(statusCode: 503, body: …)`, an uncaught `HttpError` carrying its own status and envelope, a middleware's `.stop()`, a guard's `.block()` — was formatted by the same helper that formats a crash no catcher claimed, and by the time it arrived there the two were indistinguishable: at or above `500` with `debug` off, the authored response was dropped and the client answered with `Internal Server Error`, `text/plain`, 21 bytes. Refusing to leak an internal crash is right; applying it to a response the app decided on is not. `revali_server` only emits `debug: true` when the build is **not** a release, so `revali dev` showed the correct `503` and its envelope every time and the substitution appeared at exactly the moment nobody was watching it closely. `HttpError.internal` was the sharpest edge — a documented constructor whose `code` could never reach a client in production, which defeats the branch-on-a-code feature for exactly the status range it names. The helper is now two: one for a failure the application never spoke for — an unclaimed exception, a missing handler, a payload that would not parse — which still substitutes, and one for a response the application authored, which is delivered as written. Claiming a failure without supplying a status, headers or a body authors nothing, so a bare `ExceptionCatcherResult.handled()` still receives the generic `500` and every existing client of that shape is unaffected. Logging is unchanged: a `5xx` still reaches the operator on both paths.

## 5.1.1 | 08.17.26

### Fixes

- **A `5xx` an application wrote on purpose was discarded in a released build.** Every deliberate-refusal path — an `ExceptionCatcher` returning `.handled(statusCode: 503, body: …)`, an uncaught `HttpError` carrying its own status and envelope, a middleware's `.stop()`, a guard's `.block()` — was formatted by the same helper that formats a crash no catcher claimed, and by the time it arrived there the two were indistinguishable: at or above `500` with `debug` off, the authored response was dropped and the client answered with `Internal Server Error`, `text/plain`, 21 bytes. Refusing to leak an internal crash is right; applying it to a response the app decided on is not. `revali_server` only emits `debug: true` when the build is **not** a release, so `revali dev` showed the correct `503` and its envelope every time and the substitution appeared at exactly the moment nobody was watching it closely. `HttpError.internal` was the sharpest edge — a documented constructor whose `code` could never reach a client in production, which defeats the branch-on-a-code feature for exactly the status range it names. The helper is now two: one for a failure the application never spoke for — an unclaimed exception, a missing handler, a payload that would not parse — which still substitutes, and one for a response the application authored, which is delivered as written. Claiming a failure without supplying a status, headers or a body authors nothing, so a bare `ExceptionCatcherResult.handled()` still receives the generic `500` and every existing client of that shape is unaffected. Logging is unchanged: a `5xx` still reaches the operator on both paths.

## 5.1.0 | 08.15.26

### Features

- Add `healthRoutes`, which builds the liveness and readiness routes described by a `HealthSettings`. Readiness takes an `isDraining` callback, read per request rather than captured, so the probe reflects the current shutdown state instead of the state at startup. Checks run concurrently, so the probe costs the slowest check rather than the sum of them, and a check that fails, throws, or outruns `checkTimeout` is reported as unhealthy with its name — a probe that 500s tells an orchestrator strictly less than one that names the dependency that is down.
- `shutdownServer` takes a `drainDelay`, applied after the drain is flagged but **before** the listening socket closes. Requests arriving in that window are served and tracked normally, since the accept loop does not refuse while draining. Defaults to `Duration.zero`, which is exactly the previous behaviour.
- Add `WorkerFleet` and `listenForDrainCommands`, the two halves of a shutdown that reaches worker isolates. With `AppConfig.workers > 1` every isolate binds the same port with `shared: true` and keeps its own in-flight set, while only the parent watches signals — so a `SIGTERM` drained one isolate and the parent's `exit(0)` truncated the rest, and a readiness probe balanced onto a worker reported ready while the parent was already draining. The parent now tells each worker to drain and waits for them to report back before exiting. A worker that dies, never registers, or hangs is bounded by a timeout rather than holding the process open.
- Install a `TraceContext` for every request, seeded from the caller's `X-Request-Id`, `traceparent`, `tracestate` and `baggage` headers and generating a request id when none was sent. It is installed on the `handleRequest` serve path — the one `handleRouterRequests` and the generated server actually use — as well as the older `handle` split, and for every request whether or not `di` is configured: an id that only exists when dependency injection happens to be set up is one a logger cannot rely on.
- `@RequestId` now stamps the id the ambient `TraceContext` carries rather than generating a second one, so the header and the context always name the same request. It still works outside a request, where there is no context.
- Forward `AppConfig.fromEnv` on this package's `AppConfig`. `revali_router` re-exports `revali_core` with `AppConfig` hidden and defines its own subclass, which is the one apps actually extend — a constructor that exists only upstream is unreachable from an app, and one that was only added there compiled in a `revali_core` unit test while every real app failed with "Superclass has no constructor named `AppConfig.fromEnv`".
- Respond to an uncaught `HttpError` with its own status and error envelope. Handled **after** the exception catchers, so an app that registered a catcher for its own `HttpError` subtype still wins — the envelope is a fallback for an unclaimed error, not an override.

### Fixes

- Log the exception and stack trace behind every `5xx`. An error that no `ExceptionCatcher` claimed was passed into the router's debug handling and then dropped: on the default `debug: false` path it returned a bare `Internal Server Error` and let both arguments go out of scope, so a compiled server answered `500` and wrote **nothing** anywhere. The access log records status and timing by design, and the root catch in `handleRouterRequests` only sees errors that escape the pipeline entirely — an error the catcher chain handled never reaches it — so there was no path on which the type, the message or a single frame survived. Registering catchers for an app's own typed exceptions and nothing else is the obvious way to write them, which leaves every `dart:io` exception and every `StateError` from a dependency in this gap; the failure that surfaced it was a `FileSystemException` on a Windows CI runner, diagnosable only by elimination from an adjacent request that happened to succeed. `debug` now decides what the **caller** is shown, not whether the operator is told at all: it was equally unlogged with `debug: true`, which merely put the trace in the response body, so the one configuration that made the error visible did it by disclosing internals to whoever triggered it. Gated on the status the pipeline actually produced, so the routine `4xx` — a `404`, a blocked CORS origin, a guard refusing a caller, a catcher deliberately mapping its own exception to a `401` — stay as quiet as they were.

## 5.0.0 | 08.13.26

### Breaking Changes

- `Observer.see` takes one `ObservedRequest` instead of `(Request, Future<Response>)`. This lands here as well as in `revali_core`: `revali_router.dart` re-exports `package:revali_core/revali_core.dart` hiding only `AppConfig`, `Body` and `LifecycleComponents`, so `Observer` is part of **this** package's public API and an observer that imports it from `package:revali_router/revali_router.dart` must migrate. The migration is mechanical — see `revali_core` 3.0.0.
- Depend on `revali_core: ^3.0.0`, which also removes the deprecated `DI.registerInstance<T>` / `DI.register<T>` methods.

### Features

- Resolve each request's `ObservedRequest.summary` once it completes, in **every** mode. The existing `RequestTrace` ring buffer and inspect log stay gated on `debug`/`inspect`, but telemetry is not debug tooling — gating it there would leave production with none. Observers are not awaited, and a throwing one is logged rather than allowed to affect the response or the other observers.
- Add the `@Throttle` kit: rejects a caller exceeding `max` requests per `window` with `429`, carrying `Retry-After`, `X-RateLimit-Limit` and `X-RateLimit-Remaining`. Callers are identified by client IP (resolved through `trustedProxy`), and allowances are bucketed by the matched route's *registered* path — `/api/users/:id`, not `/api/users/42` — with an optional `bucket` to pool several endpoints. It is a fixed window held in memory, so state is per process; documented as such rather than implied to be cluster-wide. Named `Throttle` rather than `RateLimit` deliberately: the barrel is imported wholesale, and `RateLimit` is a name apps already use for their own components.
- Gzip responses through the default response handler, negotiated via `Accept-Encoding` and configured with `Router.compression`. Deliberately conservative: only bodies of a known length are compressed, which leaves streaming and SSE responses untouched — gzip buffers, so compressing a stream would hold back chunks the handler meant to flush. Partial content (`206`) and already-encoded responses are skipped, and compressed responses carry `Vary: Accept-Encoding`.
- `Router` takes an optional `di`. When set, every request runs with its own `RequestScopedDI` installed for the whole pipeline — middleware, guards, interceptors, the handler and exception catchers all resolve against the same scope. Disposal waits until the response has been fully written, so streaming and SSE handlers keep their request-scoped resources for as long as they are sending. Omitting `di` leaves requests unscoped, which is how a `Router` built directly in a test behaves.
- Add graceful shutdown. `InFlightRequests` tracks requests the accept loop detached, `shutdownServer` stops the listener and waits for them within a timeout before forcing the socket closed, and `listenForShutdown` runs a callback on the first `SIGTERM`/`SIGINT` (ignoring later ones while a shutdown is already running, and skipping `SIGTERM` on Windows, which has no such signal). `handleRequests` and `handleRouterRequests` take an optional `inFlight` and behave exactly as before without it.

### Fixes

- Stop `Router.close()` throwing `Concurrent modification during iteration`. Each registered cleanup removes itself from the list as it runs, so walking the live list was unsafe whenever `close()` happened with requests still registered. Previously unreachable, because `close()` only ever ran once everything had already drained.
- Stop `BodyImpl.read()` from leaking the response body's source stream subscription when its listener cancels early. `asBroadcastStream()` defaults to pausing (not canceling) the source when the last listener drops, in case a future listener resumes it later -- but a response body is only ever read once, so the paused subscription, and whatever it held open, never got released.

## 4.0.2 | 08.06.26

### Fixes

- Stop `BodyImpl.read()` from leaking the response body's source stream subscription when its listener cancels early. `asBroadcastStream()` defaults to pausing (not canceling) the source when the last listener drops, in case a future listener resumes it later -- but a response body is only ever read once, so the paused subscription, and whatever it held open, never got released.

## 4.0.1 | 08.06.26

### Fixes

- Stop `Router` from retaining a cleanup closure per request for the life of the process. Under sustained load this was an unbounded memory leak that never released until the server restarted, even on requests with nothing to clean up.

## 4.0.0 | 08.04.26

### Breaking Changes

- `revali_router_core` and `revali_router_annotations` no longer exist as separate packages (both deprecated) — depend on `revali_core: ^2.0.0` and `revali_annotations: ^3.0.0` directly. `revali_router`'s own public API is unchanged; only the import source of the re-exported types moved.

### Features

- Add `@RequestId()` lifecycle kit to ensure every request has an ID header (default `X-Request-Id`).
- Add request inspect / timing traces for `dev --inspect`.
- Plumb `AppConfig.workers` and `AppConfig.backlog` through the router `AppConfig`.

### Fixes

- Map `MissingArgumentException` to HTTP 400 (with richer expected/actual type detail).
- Include empty-path child routes in OPTIONS `Allow` headers.
- Bind `Set` and coerced query parameters correctly.
- Harden the request accept loop against handler failures.

### Enhancements

- O(1) static route lookup; single `Find` per request.
- Cache UTF-8 bytes for JSON/string response bodies.
- Cache HTTP `Date` (~1s) and skip empty CORS / middleware / guard / interceptor stages.
- Add configurable `DefaultResponses.badRequest`.

## 3.4.0 | 06.17.26

### Features

- Add `RequestWrapper` lifecycle component that wraps the entire request pipeline in setup and teardown logic.
- Configure `trustedProxy` on the app to resolve client IP from reverse-proxy headers (e.g. `X-Forwarded-For`).
- Support wildcard path parameters (`*rest` and bare `*`).
- Allow underscores in route path segment names.
- Support `Stream<List<int>>` byte-stream request bodies.

### Fixes

- Fix coercing nested maps and lists.
- Fix route matching when path segments contain apostrophes.

### Enhancements

- Add stack traces and request context to exception handling.
- Handle uncaught errors in the request pipeline.

## 3.3.0 | 05.21.26

### Features

- Expose client IP address via `request.ip`, derived from the connection's remote address.

## 3.2.1 | 05.18.26

### Fixes

- Issue where `coerce` would incorrectly coerce JSON `null` values to `null` in maps.

## 3.2.0 | 05.18.26

### Chore

- Bump `mime` to 2.x (with aligned router stack).

## 3.1.0 | 04.28.26

### Features

- Cover `AppConfig.runStartup` with a default implementation that forwards to the provided start callback.

## 3.0.7 | 03.05.26

### Fixes

- Fix dynamic routes like `/:param` incorrectly matching a static sibling route when extra path segments exist: only return parent when remaining path segments are empty so the correct dynamic route is matched

## 3.0.6 | 03.03.26

### Fixes

- Fix OPTIONS returning 404 for prefix routes (e.g. `/api`) by returning the prefix route when path matches exactly and method is OPTIONS
- Fix OPTIONS returning 404 for paths like `/api/forums/member/:id` when a static sibling route (e.g. `member`) partially matches: continue trying other routes instead of returning when recursion yields no match

### Enhancements

- Aggregate allowed methods from descendant routes for prefix routes (no handler) so OPTIONS responses include correct `Allow` and `Access-Control-Allow-Methods` headers

## 3.0.5 | 02.18.26

### Fixes

- Fix header getter pattern matching for multi-value headers
- Skip empty header values in `forEach` callback
- Fix `CookiesImpl.headerValue()` to use `entries` for proper inheritance

### Enhancements

- Add default values for SetCookie attributes (httpOnly, secure, sameSite, path)
- Separate cookie values from SetCookie attributes in `SetCookiesImpl`
- Change `SetCookiesImpl.secure` from nullable to non-nullable `bool`

## 3.0.4 | 02.11.26

### Fixes

- Fix route matching for `OPTIONS` requests on dynamic endpoint paths (e.g. `:id`)

## 3.0.3+1 | 01.31.26

### Enhancements

- Add optional param to `headers.set(expose: true)` to expose the header to the client

## 3.0.3 | 01.31.26

### Enhancements

- Add optional param to `headers.set(expose: true)` to expose the header to the client

## 3.0.2 | 11.22.25

### Features

- Add `Reflect` class to replace `ReflectHandler`

### Chore

- Sync package versions

## 3.0.2-dev | 10.15.25

### Fix

- Dependencies

## 3.0.0+2-dev | 10.15.25

### Fix

- Dependencies

## 3.0.0+1-dev | 10.15.25

### Fix

- Payload byte length calculation

## 3.0.0-dev | 09.19.25

### Breaking Changes

- Drop all custom contexts based on lifecycle component
- Create a generic `Context` interface to replace all custom contexts
- Use new types from `revali_router_core`

## 2.4.1 | 08.26.25

### Fixes

- Issue where allowed headers were not inherited properly
- Issue where allowed headers could block requests with unknown headers

## 2.4.0 | 08.16.25

### Features

- Create new `add` method to `MutableCookies`
- Add clean up to router close method to prevent memory leaks

## 2.3.1 | 05.30.25

### Enhancements

- Check for closed connection before sending response

## 2.3.0 | 05.08.25

### Enhancements

- Binary serialization/deserialization

## 2.2.1 | 04.16.25

### Enhancements

- Catch errors when sending data over the web socket

## 2.2.0 | 04.15.25

### Features

- Create `kDebugMode`, `kProfileMode`, and `kReleaseMode` constants

## 2.1.1 | 04.09.25

### Fixes

- Issue where resolving the payload would hang on a web socket message

## 2.1.0 | 04.07.25

### Features

- Explicitly check for binary types when resolving body
- Clean up resources after response has been handled
- Support sending data asynchronously
  - As opposed to only on an event received

### Enhancements

- Check for `null` values in addition to `NullBody` body data types
- Handle exceptions when resolving body
- Coerce body types when no mime type is provided
- Improve path parameter extraction
- Force sequential execution of sent `WebSocket` messages

### Fixes

- Issue where crash would occur during SSE when connection was closed by client unexpectedly
- Issue where endpoint path would result in 404 when parent controller's path was empty

## 2.0.1 | 03.26.25

### Fixes

- Issue where `WebSocket` would only send the first message

### Features

- Create `WebSocketContext` class for context management of `WebSocket` connections
  - Specifically `close`ing the connection
- Allow empty paths for parent routes when their handler has not been set

## 2.0.0 | 03.26.25

### Breaking Changes

- Remove `UnknownBodyData`, will default to a `ByteStreamBodyData` instead
  - `UnknownBodyData` had the potential to hang if the body was a open stream

### Features

- Create `WebSocketContext` class for context management of `WebSocket` connections
  - Specifically `close`ing the connection
- Allow empty paths for parent routes when their handler has not been set

## 1.7.0 | 03.24.25

### Features

- Add support for primitive body types
  - `int`, `double`, `bool`

### Enhancements

- Clean up resources after request is complete

### Fixes

- Issue where streamed responses were not encoded correctly
- Issue where body could throw exception during `set`ting
  - Now catches and sets status code to 500
- Issue where on connect was not being called for `WebSocket`

## 1.6.1 | 02.08.25

### Chores

- Upgrade dependencies

## 1.6.0 | 02.07.25

### Features

- Use `.then` syntax instead of await to handle request operation
  - This allows for faster request handling

## 1.5.0 | 01.27.25

### Enhancements

- `ByteStreamBodyData` now extends `StreamBodyData`
- Improve server sent event response handling
  - close stream when client disconnects
  - Use new `CleanUp` class to handle cleanup

### Features

- Add `CleanUp` class to `DataHandler` on initialization

## 1.4.1 | 01.27.25

### Enhancements

- Handling responses and root errors

### Fixes

- Poor type handling for header values that could cause a response to fail

## 1.4.0 | 01.20.25

### Features

- Manage cookies with `Headers.cookies` and `Headers.setCookies`

## Features | 01.20.25

- Manage cookies with `Headers.cookies` and `Headers.setCookies`

## 1.3.0 | 12.11.24

### Features

- Combine meta types for better polymorphism support
- Add `ReadOnlyMeta` to `MiddlewareContext`

### Enhancements

- Rename `ReadOnlyDataHandler` to `ReadOnlyData`
- Rename `WriteOnlyDataHandler` to `WriteOnlyData`

### Fixes

- Issue where routes would not appear in list of routes after server restart

## 1.2.0 | 11.21.24

### Features

- Create `ExpectedHeaders` as non-optional headers to be passed into the request
- Add `ExpectedHeaders` to access control headers

### Enhancements

- Re-order the pre-request checks to
  - CORs Origins Validation
  - CORs Headers Validation
  - (CORs) Expected Headers Validation
  - Options Request Handling
  - Redirect Handling
- Return actual response in the `OPTIONS` request instead of a canned response
- Handle internal root errors with the response handler instead of deprecated `send` method

### Fix

- Add `routes` param to `SseRoute` constructor

## 1.1.0 | 11.18.24

### Features

- Support advanced `ResponseHandler` per route
  - If a response needs to be handled differently for a specific route, a `ResponseHandler` can be provided to the route to send the response to the client
- Create default response handler for `Router`
- Create `SseRoute` for Server-Sent Events
- Create `SseResponseHandler` for Server-Sent Events

### Enhancements

- Improve how streams are prepared for sending to the client

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
