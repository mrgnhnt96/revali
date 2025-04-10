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

## 1.3.0

### Features

- Add `registerLazySingleton` and `registerFactory` methods to `DI` interface
  - This is to support `factories`, so that dependencies can be re-created each time they are resolved

### Future BREAKING Changes

- `DI.register` will be removed in favor of `registerLazySingleton` and `registerFactory`
- `DI.registerInstance` will be removed in favor of `registerSingleton`

<!-- REVALI ROUTER -->

# revali_router

## 2.1.1

### Fixes

- Issue where resolving the payload would hang on a web socket message

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

## 1.12.1

### Enhancements

- Handle `dynamic` types when accessing the data from the request

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
