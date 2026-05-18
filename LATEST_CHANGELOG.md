<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.1.0

### Chore

- Bump `analyzer` / `dart_style` and migrate to the analyzer 10 element APIs.

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

## 3.2.1

### Fixes

- Issue where `coerce` would incorrectly coerce JSON `null` values to `null` in maps.

# revali_router_annotations

## 2.0.2+1

### Fix

- Dependencies

# revali_router_core

## 2.1.0

### Chore

- Bump `mime` to 2.x.

<!-- CONSTRUCTS -->

# revali_server

## 2.2.0

### Chore

- Bump `analyzer` / `dart_style`; migrate converters to analyzer 10.

<!-- REVALI CLIENT -->

# revali_client

## 2.0.4

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

# revali_client_gen

## 2.1.0

### Chore

- Bump `analyzer` / `dart_style`; migrate codegen to analyzer 10.

### Fix

- Issue where `body` param conflicted with local variable name
