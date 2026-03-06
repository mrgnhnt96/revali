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

## 1.4.0

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

<!-- REVALI ROUTER -->

# revali_router

## 3.0.7

### Fixes

- Fix dynamic routes like `/:param` incorrectly matching a static sibling route when extra path segments exist: only return parent when remaining path segments are empty so the correct dynamic route is matched

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

## 2.0.5

### Features

- Handle server components that use constructors to set fields (initializer list values), e.g. `const Auth.admin() : requireAdmin = true`

<!-- REVALI CLIENT -->

# revali_client

## 2.0.4

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

# revali_client_gen

## 2.0.2

### Chore

- Sync package versions
