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

## 1.3.0

### Features

- Create classes to support records

### Enhancements

- Remove type argument from `RevaliDirectory`
- Merge `MetaReturnType` into `MetaType`

# revali_core

## 1.2.0

### Enhancements

- Require `Object` type for `DI` registrations

<!-- REVALI ROUTER -->

# revali_router

## 1.7.0

### Features

- Add support for primitive body types
  - `int`, `double`, `bool`

### Enhancements

- Clean up resources after request is complete

### Fixes

- Issue where streamed responses were not encoded correctly
- Issue where body could throw exception during `set`ting
  - Now catches and sets status code to 500
- Issue where on connect was not being called for `WebSocket`

# revali_router_annotations

## 1.2.0

### Features

- Add `Cookie` param annotation to retrieve cookies from request

# revali_router_core

## 1.6.0

### Features

- Support for `Cookie` param

### Enhancements

- Change return type of `MutableBody.replace` method to `Future<void>`

<!-- CONSTRUCTS -->

# revali_server

## 1.10.1

### Features

- Support for `Cookie` param
- Support for generic types in `LifecycleComponent`
<!-- Add docs for Inject! -->
- Support `Inject` types in annotations
  - Allows for constant resolution of annotations that require dependency injection and need arguments
- Support record types

<!-- REVALI CLIENT -->

# revali_client

## 1.0.1

Initial Release!

# revali_client_gen

## 1.0.1

Initial Release!
