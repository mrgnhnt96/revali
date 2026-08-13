<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.3.0

### Features

- The generated server serves liveness and readiness probes. `healthRoutes` is registered alongside the `public` routes — **outside** the app prefix, so they answer on the bare paths an orchestrator is configured with rather than under `/api`. Readiness closes over the server's `InFlightRequests`, so it reports `503` as soon as a shutdown begins.
- The generated shutdown honours `AppConfig.drainDelay`, but only on `SIGTERM`. `SIGINT` is a human at a terminal who wants the process gone now; `SIGTERM` is an orchestrator, which is who the delay exists for.
- The generated shutdown reaches worker isolates. Workers are spawned with a registration port and drain on the parent's command instead of watching signals themselves, and the parent drains its own isolate concurrently with theirs before exiting — so probes report `503` across the whole fleet at once, and `exit(0)` no longer truncates requests still running in a worker. Verified against a running three-worker server: with uneven request durations, the longest request on a worker returns `200` where it previously died with no response at all.

# revali_annotations

## 3.1.0

### Fixes

- Raise the `revali_core` floor to `^3.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. `revali_core` 3.0.0 is a new major, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 3.0.0 behind on `revali_core: ^2.0.0` would make it unresolvable alongside every other package in this round.

# revali_construct

## 2.4.0

### Features

- Add `TargetOs`/`Arch` enums and `CompiledExecutable` to describe native executables compiled by `revali build`.
- Add `RevaliBuildContext.compiledExecutables`, populated whenever `revali.yaml` has a `build:` section, so build-type constructs can package an already-compiled executable instead of compiling one themselves.
- Add a `build:` section to `RevaliYaml` (`BuildSettingsConfig`) for `target_os`, `target_arch`, and `strip_debug_info`.
- Allow `AnyFile` to carry binary content via a new `bytes` field, written with `writeAsBytes` instead of `writeAsString` when present.

# revali_core

## 3.1.0

### Features

- Add health probes to `AppConfig`. `HealthSettings` (exposed as `AppConfig.health`) configures a liveness path (`/healthz`) and a readiness path (`/readyz`), a list of `HealthCheck`s consulted by readiness, and a per-check `checkTimeout`. Either path can be set to `null`, or the whole thing disabled with `const HealthSettings.disabled()`.
- Liveness and readiness answer different questions, and the split is deliberate: liveness failing tells an orchestrator to **restart** the process, so it keeps returning `200` during a graceful shutdown, while readiness flips to `503`. Failing liveness mid-drain would kill exactly the in-flight requests the drain exists to protect. Liveness also runs no checks — consulting a database there turns one database blip into a restart storm.
- Add `AppConfig.drainDelay` (default `Duration.zero`, so existing behaviour is unchanged). Closing the listening socket is invisible to a load balancer: it keeps routing until its own readiness probe fails, and every request it sends in the meantime hits a closed socket. This is the window in which readiness reports `503` while the server can still serve. Behind a load balancer, set it longer than the probe's period times its failure threshold, and keep `drainDelay + shutdownTimeout` under the platform's kill grace period.

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

## 2.1.0

### Features

- Send streamed request bodies. A `Stream<List<int>>` or `Stream<String>` body is now handed to the transport and sent incrementally, so a large upload never has to fit in memory; previously this threw `UnimplementedError`. The server side already worked — `@Body() Stream<List<int>>` reads the payload as it arrives — so this completes the round trip. `HttpRequest` gains `bodyStream`. Any other `Stream<T>` throws an `ArgumentError` naming the supported types rather than inventing a framing format the server has no binding for.

### Fixes

- Parse every `Set-Cookie` value, and stop storing cookie attributes as cookies. A response setting several cookies arrives as one comma-joined header, which `CookieParser` could not match at all, so none were saved; the attributes it did match put `Path` and `Expires` into storage. Splitting now happens only at a comma beginning a new `name=` pair, so the comma inside an `Expires` date cannot split a cookie in half.
- Actually enable cross-origin cookie credentials on web by setting `BrowserClient.withCredentials = true`, instead of adding a literal `credentials: 'include'` HTTP header (a no-op -- `credentials` is a `fetch()`-level option, not a header, so it never did anything). Non-web platforms are unaffected (no browser cookie jar to opt into).

# revali_client_gen

## 2.4.0

### Fixes

- Raise the `revali_core` floor to `^3.0.0` and the `revali_router` floor to `^5.0.0`. Nothing in this package changed; it is re-released so the published set still resolves. Both are new majors this round, and a dependent's constraint is only rewritten if that dependent is itself part of the release — leaving 2.3.0 behind on `^2.0.0` / `^4.0.2` would make it unresolvable alongside them.
