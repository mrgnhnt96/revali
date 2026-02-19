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

## 3.0.5

### Fixes

- Fix header getter pattern matching for multi-value headers
- Skip empty header values in `forEach` callback
- Fix `CookiesImpl.headerValue()` to use `entries` for proper inheritance

### Enhancements

- Add default values for SetCookie attributes (httpOnly, secure, sameSite, path)
- Separate cookie values from SetCookie attributes in `SetCookiesImpl`
- Change `SetCookiesImpl.secure` from nullable to non-nullable `bool`

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
