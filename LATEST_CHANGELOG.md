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

## 3.0.6

### Fixes

- Fix OPTIONS returning 404 for prefix routes (e.g. `/api`) by returning the prefix route when path matches exactly and method is OPTIONS
- Fix OPTIONS returning 404 for paths like `/api/forums/member/:id` when a static sibling route (e.g. `member`) partially matches: continue trying other routes instead of returning when recursion yields no match

### Enhancements

- Aggregate allowed methods from descendant routes for prefix routes (no handler) so OPTIONS responses include correct `Allow` and `Access-Control-Allow-Methods` headers

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
