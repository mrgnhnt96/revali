<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.2.0

### Features

- The generated server now shuts down gracefully. On `SIGTERM`/`SIGINT` it stops accepting connections, waits for in-flight requests up to `AppConfig.shutdownTimeout`, runs `AppConfig.onServerStopped`, and exits `0` — so a deploy or scale-down no longer truncates responses that were mid-flight. Handlers are installed only for a server Revali created itself, never when one is provided (as `TestServer` does) and never in worker isolates.
- Add a `build:` section to `revali.yaml`. Its presence tells `revali build` to compile the server via `dart compile exe --target-os --target-arch`, cross-compiling to Linux from any host OS. Compiled executables are exposed to build-type constructs (e.g. `revali_docker`) via `RevaliBuildContext.compiledExecutables`, so they can package what was already compiled instead of compiling anything themselves. Supports `strip_debug_info` to split AOT debug info out of the executable for a smaller binary.

# revali_annotations

## 3.0.0

### Breaking Changes

- Merge `revali_router_annotations` into this package (that package is deprecated). `@Query`, `@Param`, `@Header`, `@Cookie`, `@Ip`, `@Guards`, `@Middlewares`, `@Wrappers`, `@Intercepts`, `@Combines`, `@AddData`, `@MetaData`, `@SetHeader`, `@StatusCode`, `@Catches`, `@Dep`, `@Binds`, `Bind`, `Pipe`, `RequestHeaders`/`ResponseHeaders`, `RequestCookies`/`ResponseCookies`, and `LifecycleComponent`/`LifecycleComponents` now live here.
- Depend on `revali_core: ^2.0.0`.
- `AllowOrigins`, `PreventHeaders`, and `ExpectHeaders` now live in `revali_core`; still re-exported here for compatibility.

# revali_construct

## 2.4.0

### Features

- Add `TargetOs`/`Arch` enums and `CompiledExecutable` to describe native executables compiled by `revali build`.
- Add `RevaliBuildContext.compiledExecutables`, populated whenever `revali.yaml` has a `build:` section, so build-type constructs can package an already-compiled executable instead of compiling one themselves.
- Add a `build:` section to `RevaliYaml` (`BuildSettingsConfig`) for `target_os`, `target_arch`, and `strip_debug_info`.
- Allow `AnyFile` to carry binary content via a new `bytes` field, written with `writeAsBytes` instead of `writeAsString` when present.

# revali_core

## 3.0.0

### Breaking Changes

- Remove the deprecated `DI` registration methods. `registerInstance<T>` and `register<T>` are gone from `DI`, `DIImpl`, `DIHandler`, and `RequestScopedDI`; use `registerSingleton<T>` and `registerFactory<T>` / `registerLazySingleton<T>` instead. The `Factory<T>` typedef is unchanged.

### Features

- Add graceful-shutdown configuration to `AppConfig`: `handleShutdownSignals` (default `true`) to opt out of signal handling, `shutdownTimeout` (default 15s) to bound how long in-flight requests are awaited, and an `onServerStopped` hook that runs once they have drained so the app can release databases, consumers and file handles.

### Fixes

- Add `SetCookies.headerValues()`, returning one formatted `Set-Cookie` line per cookie instead of an invalid comma/semicolon-joined line (RFC 6265 §4.1.1). Published `revali_router` 4.0.2 already calls this method against the `SetCookies` interface, so any project resolving `revali_core` 2.0.0 alongside it fails to compile.
- Reflect `https` (not `http`) in the "Serving at ..." startup log line when TLS is enabled via `--cert`/`--key` or `AppConfig.secure`.

# revali_test

## 1.0.0

### Features

- First release. `revali_test` was previously `publish_to: none`, so the testing helpers the docs and the internal suite rely on were unavailable to anyone outside this repo. It exposes `TestServer`, which stands in for an `HttpServer` so a generated server runs in-process without binding a socket, plus `TestRequest`/`TestResponse`/`TestHeaders` and the `expectRecentHttpDate` matcher.

# revali_mcp

## 0.1.0

### Features

- First release. `revali_mcp` was previously `publish_to: none`, so the Cursor configuration in the repo README could not resolve for anyone outside this repo. Exposes `list_routes`, `get_route`, `doctor`, `recent_requests`, and `create_scaffold` over an MCP stdio server.

### Fixes

- Frame stdio messages by byte count rather than decoded character count. `Content-Length` counts bytes, so any message body containing a non-ASCII character left the server waiting on data that had already arrived, and it never replied. Responses are likewise written as UTF-8 bytes instead of through `stdout.write`, which re-encodes using `Stdout.encoding` and could disagree with the length already announced.

<!-- REVALI ROUTER -->

# revali_router

## 4.1.0

### Features

- Add graceful shutdown. `InFlightRequests` tracks requests the accept loop detached, `shutdownServer` stops the listener and waits for them within a timeout before forcing the socket closed, and `listenForShutdown` runs a callback on the first `SIGTERM`/`SIGINT` (ignoring later ones while a shutdown is already running, and skipping `SIGTERM` on Windows, which has no such signal). `handleRequests` and `handleRouterRequests` take an optional `inFlight` and behave exactly as before without it.

### Fixes

- Stop `Router.close()` throwing `Concurrent modification during iteration`. Each registered cleanup removes itself from the list as it runs, so walking the live list was unsafe whenever `close()` happened with requests still registered. Previously unreachable, because `close()` only ever ran once everything had already drained.
- Stop `BodyImpl.read()` from leaking the response body's source stream subscription when its listener cancels early. `asBroadcastStream()` defaults to pausing (not canceling) the source when the last listener drops, in case a future listener resumes it later -- but a response body is only ever read once, so the paused subscription, and whatever it held open, never got released.

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

## 1.1.0

### Fix

- Depend on `revali_annotations ^3.0.0` (previously `revali_router_annotations ^2.2.0`). The router/annotations consolidation refactor already dropped this dependency in source, but the package version was never bumped, so pub.dev's 1.0.0 stayed pinned to `revali_router_annotations`, which pulls in `revali_router_core ^2.3.0` -> `revali_core ^1.6.0`, conflicting with `revali ^3.0.0`'s `revali_core ^2.0.0` requirement.

<!-- REVALI CLIENT -->

# revali_client

## 2.0.5

### Fixes

- Actually enable cross-origin cookie credentials on web by setting `BrowserClient.withCredentials = true`, instead of adding a literal `credentials: 'include'` HTTP header (a no-op -- `credentials` is a `fetch()`-level option, not a header, so it never did anything). Non-web platforms are unaffected (no browser cookie jar to opt into).

# revali_client_gen

## 2.3.0

### Fix

- Depend on `revali_router ^4.0.0` and `revali_annotations ^3.0.0` (previously `^3.4.0` / `^2.0.2`). The router/annotations consolidation refactor already raised this dependency floor in source, but the package version was never bumped, so pub.dev's 2.2.0 stayed pinned to the old constraints and couldn't resolve alongside `revali_router` 4.x or any construct requiring `revali_annotations` ^3.0.0 (e.g. `revali_docker` via `revali_construct`).

<!-- TOOLS -->

# og_card

## 0.1.0

### Features

- Initial version. Renders Open Graph social card images as PNG in pure Dart, with no native dependencies. Used at build time by `doc-site/tool/gen_og_cards.dart`.
