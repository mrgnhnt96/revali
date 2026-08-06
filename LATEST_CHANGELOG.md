<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 3.1.0

### Features

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

## 2.0.0

### Breaking Changes

- Merge `revali_router_core` into this package (that package is deprecated). `Request`, `Response`, `Guard`, `Middleware`, `Interceptor`, `ExceptionCatcher`, `Observer`, `CombineComponents`, `ResponseHandler`, `Meta`, `MetaScope`, `Reflect`, `RouteEntry`, `TrustedProxy`, `Cookies`, `Headers`, `Body`, and related types now live here.
- Move `AllowOrigins`, `PreventHeaders`, and `ExpectHeaders` here from `revali_annotations` (still re-exported from there for compatibility).

### Features

- Add `AppConfig.workers` for multi-isolate serving (`shared: true` when > 1).
- Add `AppConfig.backlog` to control the `HttpServer.bind` listen backlog.

<!-- REVALI ROUTER -->

# revali_router

## 4.0.1

### Fixes

- Stop `Router` from retaining a cleanup closure per request for the life of the process. Under sustained load this was an unbounded memory leak that never released until the server restarted, even on requests with nothing to clean up.

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
