<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.0.9

### Features

- Add `hot_reload.exclude` in `revali.yaml` to ignore custom paths on reload (paths can be absolute or relative to revali.yaml)

### Enhancements

- Preserve terminal content when running with `--loud` (verbose) mode instead of clearing screen on reload

# revali_annotations

## 2.0.2

### Chore

- Sync package versions

# revali_construct

## 2.0.4

### Features

- Add `HotReloadConfig` model with `exclude` list for hot reload path filtering
- Add `hot_reload` configuration to `RevaliYaml` for excluding paths from reload triggers

# revali_core

## 1.5.0

### Features

- Add `runStartup` on `AppConfig` so apps can wrap async server startup (bind, DI, routes); the default implementation forwards to the provided `start` callback unchanged.

<!-- REVALI ROUTER -->

# revali_router

## 3.1.0

### Features

- Cover `AppConfig.runStartup` with a default implementation that forwards to the provided start callback.

# revali_router_annotations

## 2.0.2+1

### Fix

- Dependencies

# revali_router_core

## 2.0.3+1

### Enhancements

- Add optional param to `headers.set(expose: true)` to expose the header to the client

<!-- CONSTRUCTS -->

# revali_server

## 2.1.0

### Features

- Emit the `runStartup` callback in generated `createServer` with a block body instead of an arrow function so multi-statement startup code is valid Dart.

<!-- REVALI CLIENT -->

# revali_client

## 2.0.4

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

# revali_client_gen

## 2.0.2

### Chore

- Sync package versions
