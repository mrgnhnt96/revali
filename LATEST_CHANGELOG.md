<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.1.0

### Features

- Support `SSE` methods

### Chores

- Upgrade dependencies

# revali_annotations

## 1.1.0

### Features

- Create `SSE` annotation for Server-Sent Events

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

## 1.1.0

### Features

- Support low-level `ResponseHandler` per route
  - If a response needs to be handled differently for a specific route, a `ResponseHandler` can be provided to the route to send the response to the client
- Create default response handler for `Router`
- Create `SseRoute` for Server-Sent Events
- Create `SseResponseHandler` for Server-Sent Events

### Enhancements

- Improve how streams are prepared for sending to the client

### Chores

- Upgrade dependencies

# revali_router_annotations

## 1.0.1

### Chores

- Upgrade dependencies

# revali_router_core

## 1.1.0

### Features

- Create `ResponseHandler` interface
  - A `ResponseHandler` is a low-level handler that can be provided to a route to send the response to the client differently

### Chores

- Upgrade dependencies

<!-- CONSTRUCTS -->

# revali_server

## 1.1.0

### Features

- Support `ResponseHandler` annotations
- Support `SSE` annotation

### Chores

- Upgrade dependencies
