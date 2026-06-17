<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.2.0

### Features

- Resolve package dependencies via `package_config` for more reliable workspace resolution.

### Enhancements

- Normalize file paths on Windows so analyzer, construct runner, and VM service handlers work cross-platform.
- Handle uncaught errors during dev server startup and hot reload with stack traces.
- Improve workspace root detection and failure diagnostics.

# revali_annotations

## 2.0.2

### Chore

- Sync package versions

# revali_construct

## 2.2.0

### Features

- Add `CoalescingReloadQueue` to serialize hot-reload restarts and coalesce concurrent reload requests.
- Add `fileUriToRelativeImportPath` for cross-platform import paths in generated Dart source.

### Enhancements

- Use POSIX paths in generated `part` and `part of` directives for Windows compatibility.
- Handle uncaught errors during hot reload with stack traces.

# revali_core

## 1.6.0

### Features

- Add `RequestScopedDI` for request-scoped dependency injection, installable via a request wrapper and `Zone`.

<!-- REVALI ROUTER -->

# revali_router

## 3.4.0

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

# revali_router_annotations

## 2.2.0

### Features

- Add `@Wrappers` annotation for registering request wrappers on controllers and routes.

# revali_router_core

## 2.3.0

### Features

- Add `RequestWrapper` interface and `WrapperResult` type alias.
- Add `TrustedProxy` for resolving client IP from proxy headers.
- Add `wildcardParameters` getter on `Request`.

<!-- CONSTRUCTS -->

# revali_server

## 2.4.0

### Features

- Generate request wrapper lifecycle components and nest them in the pipeline.
- Generate wildcard path parameter bindings.
- Support `Stream<List<int>>` body parameters for file uploads.
- Cast `Headers` to typed request/response header interfaces in generation.

### Enhancements

- Use Windows-safe forward-slash import paths in generated code.
- Include route and parameter context in generated exception throws.
- Skip private and static lifecycle component methods during codegen.

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
