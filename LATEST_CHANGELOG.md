<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.1.1

### Chore

- Upgrade dependencies
- Clean up lint warnings

### Chores

- Upgrade dependencies

# revali_annotations

## 1.2.0

### Features

- Create `ExpectHeaders` annotation
- Add new `common` constructor for `AllowHeaders`

# revali_construct

## 1.1.0

### Features

- Support `SSE` methods

### Chores

- Upgrade dependencies

# revali_core

## 1.0.0

- Initial Release

<!-- REVALI ROUTER -->

# revali_router

## 1.2.0

### Features

- Create `ExpectedHeaders` as non-optional headers to be passed into the request
- Add `ExpectedHeaders` to access control headers

### Enhancements

- Re-order the pre-request checks to
  - CORs Origins Validation
  - CORs Headers Validation
  - (CORs) Expected Headers Validation
  - Options Request Handling
  - Redirect Handling
- Return actual response in the `OPTIONS` request instead of a canned response
- Handle internal root errors with the response handler instead of deprecated `send` method

### Fix

- Add `routes` param to `SseRoute` constructor

# revali_router_annotations

## 1.0.1

### Chores

- Upgrade dependencies

# revali_router_core

## 1.2.0

### Features

- Create `ExpectedHeaders` as non-optional headers to be passed into the request
- Add `ExpectedHeaders` to lifecycle components

<!-- CONSTRUCTS -->

# revali_server

## 1.2.0

### Features

- Support `expectedHeaders` argument
- Allow multiple `AllowedHeaders`, `AllowedOrigins` and `ExpectedHeaders` to be provided on a single route/controller
