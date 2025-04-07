<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.4.1

### Enhancements

- Print `GET (SSE)` when using `@SSE` methods

# revali_annotations

## 1.3.0

### Features

- Create `Inject` class to resolve types at runtime and compile-time

### Enhancements

- Add new constructor `WebSocket.mode`

# revali_construct

## 1.5.0

### Features

- Create `MetaToJson` class to provide details about `toJson` methods

# revali_core

## 1.2.0

### Enhancements

- Require `Object` type for `DI` registrations

<!-- REVALI ROUTER -->

# revali_router

## 2.1.0

### Features

- Explicitly check for binary types when resolving body
- Clean up resources after response has been handled
- Support sending data asynchronously
  - As opposed to only on an event received

### Enhancements

- Check for `null` values in addition to `NullBody` body data types
- Handle exceptions when resolving body
- Coerce body types when no mime type is provided
- Improve path parameter extraction
- Force sequential execution of sent `WebSocket` messages

### Fixes

- Issue where crash would occur during SSE when connection was closed by client unexpectedly
- Issue where endpoint path would result in 404 when parent controller's path was empty

# revali_router_annotations

## 1.3.0

### Enhancements

- Change return type for `Pipe.transform` to `Future<T>`

# revali_router_core

## 1.8.0

### Features

- Add `MutableBody` getter to `MutableRequest`

### Enhancements

- Create `AsyncWebSocketSender` interface to send messages asynchronously

<!-- CONSTRUCTS -->

# revali_server

## 1.12.0

### Features

- Support default arguments for parameters

### Enhancements

- Clean up argument generation for methods
- Clean up class parsing from analyzed files

<!-- REVALI CLIENT -->

# revali_client

## 1.1.0

### Features

- Add `ExcludeFromClient` annotation to exclude controllers/methods from being generated in the client

# revali_client_gen

## 1.2.0

### Features

- Support `ExcludeFromClient` annotation to exclude controllers/methods from being generated in the client
- Support explicit types for `toJson` return types
- Support explicit types for `fromJson` parameters

### Fixes

- Issue where multiple path parameters would malform the generated endpoint path

### Enhancements

- Mark parameters as optional if there is a default value or if the type is nullable
