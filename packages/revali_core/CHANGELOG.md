# CHANGELOG

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
