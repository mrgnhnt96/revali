<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.4.0

### Enhancements

- Improve and clean up `MetaType` resolution
- Safely retrieve constructor from the controller

### Features

- Add (hidden) `--generate-only` flag to `dev` command
- Support for `workspace`s in `pubspec.yaml`

### Fixes

- Add `--profile` flag to `dev` (runner) command

# revali_annotations

## 1.3.0

### Features

- Create `Inject` class to resolve types at runtime and compile-time

### Enhancements

- Add new constructor `WebSocket.mode`

# revali_construct

## 1.4.0

### Features

- Create `MetaFromJson` class to improve support for `fromJson` factory/static methods
- Resolve `fromJson` static methods within types

### Breaking Changes (future)

- Deprecate `hasFromJsonConstructor` in `MetaType`
  - Use `hasFromJson` instead

# revali_core

## 1.2.0

### Enhancements

- Require `Object` type for `DI` registrations

<!-- REVALI ROUTER -->

# revali_router

## 2.0.1

### Fixes

- Issue where `WebSocket` would only send the first message

### Features

- Create `WebSocketContext` class for context management of `WebSocket` connections
  - Specifically `close`ing the connection
- Allow empty paths for parent routes when their handler has not been set

# revali_router_annotations

## 1.2.0

### Features

- Add `Cookie` param annotation to retrieve cookies from request

# revali_router_core

## 1.7.0

### Features

- Create `CloseWebSocket` class to manually close a `WebSocket`
- Create `WebSocketContext` class for context management of `WebSocket` connections
- Add `code` and `reason` params to `MutableWebSocketRequest.close`

<!-- CONSTRUCTS -->

# revali_server

## 1.11.2

### Fixes

- Issue where arguments were not passed properly to class from type references

<!-- REVALI CLIENT -->

# revali_client

## 1.0.1

Initial Release!

# revali_client_gen

## 1.1.1

### Fixes

- Issue where not all imports were being added to the generated code from type's type arguments
