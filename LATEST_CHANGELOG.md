<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.0.6

### Fixes

- Handle `deleteFile` errors gracefully when path doesn't exist in memory provider
- Buffer server stdout/stderr for reliable diagnostics when process exits unexpectedly
- Log diagnostics before server crashes

### Enhancements

- Improved error logging for file watcher errors (now includes stack trace)
- More informative shutdown and signal logging

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

## 3.0.4

### Fixes

- Fix route matching for `OPTIONS` requests on dynamic endpoint paths (e.g. `:id`)

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

## 2.0.3

### Features

- Add `Body` and `PayloadBody` to inferred types

### Enhancements

- Improve error message when inferred type fails to resolve
- Print stack trace when resolving routes throws

<!-- REVALI CLIENT -->

# revali_client

## 2.0.3

### Enhancements

- Add ability to update headers from within request interceptors

# revali_client_gen

## 2.0.2

### Chore

- Sync package versions
