<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.0.8

### Enhancements

- Add retry logic to analyzer updates to prevent inconsistent analysis errors

# revali_annotations

## 2.0.2

### Chore

- Sync package versions

# revali_construct

## 2.0.3

### Enhancements

- Prints error messages when exceptions are thrown during server creation

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

## 2.0.4

### Fixes

- **revali_docker**: Remove default values from `ARG` declarations in generated Dockerfile; values must now be provided via `--build-arg` at build time instead of being baked into the file

<!-- REVALI CLIENT -->

# revali_client

## 2.0.4

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

# revali_client_gen

## 2.0.2

### Chore

- Sync package versions
