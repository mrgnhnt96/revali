<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.3.0

### Features

- Create new class for `Type`s on method parameters
  - Add property `hasFromJsonConstructor`

### Enhancements

- Clean up import path retrieval

# revali_annotations

## 1.2.0

### Features

- Create `ExpectHeaders` annotation
- Add new `common` constructor for `AllowHeaders`

# revali_construct

## 1.2.0

### Features

- Create class `MetaType` for method parameter types

# revali_core

## 1.2.0

### Enhancements

- Require `Object` type for `DI` registrations

<!-- REVALI ROUTER -->

# revali_router

## 1.5.0

### Enhancements

- `ByteStreamBodyData` now extends `StreamBodyData`
- Improve server sent event response handling
  - close stream when client disconnects
  - Use new `CleanUp` class to handle cleanup

### Features

- Add `CleanUp` class to `DataHandler` on initialization

# revali_router_annotations

## 1.1.0

### Features

- Add `LifecycleComponent` annotation to support creating lifecycle components using classes
- Add `LifecycleComponents` annotation to support registering multiple lifecycle components via type referencing

# revali_router_core

## 1.5.0

### Features

- Create `CleanUp` class to handle cleanup of resources after request handling
- Add `cleanUp` method to `BodyData` to handle cleanup

<!-- CONSTRUCTS -->

# revali_server

## 1.8.0

### Features

- Create CLI to generate components
