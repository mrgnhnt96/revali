<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.0.0

### Breaking Changes

- Server code generation is now built into `revali` — `revali_server` no longer exists as a separate package. Remove it from your `dev_dependencies`; `revali` alone is sufficient.
- `revali create` scaffolds in-process; it no longer shells out to `revali_server create`.
- Depend on `revali_router: ^4.0.0`, `revali_annotations: ^3.0.0`, and `revali_core: ^2.0.0`.
- The `revali.yaml` key for customizing `create` scaffold paths is now `server:` (was `revali_server:`).

### Features

- Add `routes`, `doctor`, and `create` CLI commands for route inspection, diagnostics, and scaffolding.
- Add `--inspect` on `dev` to record recent requests to `.revali/inspect/requests.jsonl`.
- Add headless `.revali_cmd` channel for reload/recovery without a TTY.
- Emit `.revali/server/routes.json` route manifest on generate.
- Spawn shared `HttpServer` worker isolates when `AppConfig.workers` > 1.
- Wire request-inspect hooks into generated server startup.

### Enhancements

- Share construct kernels across packages and persist the analyzer byte store for faster rebuilds.
- Harden hot reload: atomic promote, kernel invalidation on package changes, analyzer overlay for new routes, and rapid-churn recovery.
- Discover `app.dart` and warn when falling back to the default app.
- Exclude `bin` / `test` / `tool` from hot-reload watches.
- Stabilize the `revali dev` status board: `[READY]`/`[RELOAD]` tags, preserve Serving at after clear/reload, and respect loud mode on `c`.
- Pass `AppConfig.backlog` into server bind.
- Serve with a single route `Find` on the hot path.

### Fixes

- Tolerate stdin mode errors on non-TTY terminals.
- Pick up local path-dependency edits during `revali dev` by notifying every analysis context (app context no longer keeps a stale copy).
- Return HTTP 400 for missing/invalid parameter bindings (`MissingArgumentException`).
- Bind `Set` and coerced query parameters correctly (including coerced values to `String` params).

# revali_annotations

## 3.0.0

### Breaking Changes

- Merge `revali_router_annotations` into this package (that package is deprecated). `@Query`, `@Param`, `@Header`, `@Cookie`, `@Ip`, `@Guards`, `@Middlewares`, `@Wrappers`, `@Intercepts`, `@Combines`, `@AddData`, `@MetaData`, `@SetHeader`, `@StatusCode`, `@Catches`, `@Dep`, `@Binds`, `Bind`, `Pipe`, `RequestHeaders`/`ResponseHeaders`, `RequestCookies`/`ResponseCookies`, and `LifecycleComponent`/`LifecycleComponents` now live here.
- Depend on `revali_core: ^2.0.0`.
- `AllowOrigins`, `PreventHeaders`, and `ExpectHeaders` now live in `revali_core`; still re-exported here for compatibility.

# revali_construct

## 2.3.0

### Features

- Allow `ServerDirectory` to include additional generated files alongside `server.dart` via `additionalFiles`.

# revali_core

## 2.0.0

### Breaking Changes

- Merge `revali_router_core` into this package (that package is deprecated). `Request`, `Response`, `Guard`, `Middleware`, `Interceptor`, `ExceptionCatcher`, `Observer`, `CombineComponents`, `ResponseHandler`, `Meta`, `MetaScope`, `Reflect`, `RouteEntry`, `TrustedProxy`, `Cookies`, `Headers`, `Body`, and related types now live here.
- Move `AllowOrigins`, `PreventHeaders`, and `ExpectHeaders` here from `revali_annotations` (still re-exported from there for compatibility).

### Features

- Add `AppConfig.workers` for multi-isolate serving (`shared: true` when > 1).
- Add `AppConfig.backlog` to control the `HttpServer.bind` listen backlog.

<!-- REVALI ROUTER -->

# revali_router

## 4.0.0

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

<!-- CONSTRUCTS -->

# revali_docker

## 1.0.0

### Features

- Extracted from `revali_server` into its own standalone build construct. Generates production-ready, multi-stage Dockerfiles for your Revali server — install it directly with `dart pub add revali_docker --dev`.

<!-- SWAGGER -->

# revali_swagger_annotations

## 1.0.0

### Features

- Initial release with `@ApiInfo`, `@ApiTag`, `@ApiSummary`, `@ApiDescription`, `@ApiResponse`, `@ApiHidden`, and `@ApiType` annotations for customizing generated OpenAPI output.

# revali_swagger

## 1.0.0

### Features

- Initial release: generate OpenAPI 3.0.3 specs from Revali routes, parameters, and return types.
- Write both `swagger.yaml` and `swagger.json` on every run.
- Automatic JSON Schema for Dart primitives, collections, records, enums, and user-defined classes.
- Optional annotation overrides for summaries, tags, responses, and custom schema types.

<!-- REVALI CLIENT -->

# revali_client

## 2.0.4

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

# revali_client_gen

## 2.2.0

### Features

- Generate streaming clients for `Future<Stream<List<int>>>` return types (file downloads).

### Enhancements

- Use Windows-safe import paths in generated code.
- Skip private and static lifecycle component methods during codegen.

### Fix

- Flavor selection when a single app is configured without an explicit flavor.
