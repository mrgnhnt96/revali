<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.1.1

### Enhancements

- Improve logging when conflicting routes are detected.
- Preserve the "Serving at" message in the console after hot reload and screen clear.

### Enhancements

- Generate into `.revali.staging` and only replace `.revali` after generation succeeds, so an interrupted rebuild no longer removes `revali_client/pubspec.yaml` and breaks workspace `dart pub get`.

# revali_annotations

## 2.0.2

### Chore

- Sync package versions

# revali_construct

## 2.1.0

### Chore

- Bump `analyzer` and migrate generated-tooling code to analyzer 10.

# revali_core

## 1.5.0

### Features

- Add `runStartup` on `AppConfig` so apps can wrap async server startup (bind, DI, routes); the default implementation forwards to the provided `start` callback unchanged.

<!-- REVALI ROUTER -->

# revali_router

## 3.3.0

### Features

- Expose client IP address via `request.ip`, derived from the connection's remote address.

# revali_router_annotations

## 2.1.0

### Features

- Add `@Ip` annotation for injecting the client IP into route handlers.

# revali_router_core

## 2.2.0

### Features

- Add `ip` getter to `Request` and `UnderlyingRequest`.

<!-- CONSTRUCTS -->

# revali_server

## 2.3.0

### Features

- Add codegen support for `@Ip` route parameters.
- Substitute generic type arguments on lifecycle component registrations into guard/middleware params (e.g. `@RateLimit<GetBody>()` resolves `@Body() T`).
- Instantiate lifecycle components in generated wrappers with their type arguments (e.g. `RateLimit<GetBody>()`).

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

## 2.1.0

### Chore

- Bump `analyzer` / `dart_style`; migrate codegen to analyzer 10.

### Features

- Resolve generic lifecycle type arguments from route annotations for client codegen.

### Fix

- Issue where `body` param conflicted with local variable name
- Duplicate `body` params in generated clients when routes use generic lifecycle components (e.g. `@RateLimit<GetBody>()` with `@Query() GetBody body`).
