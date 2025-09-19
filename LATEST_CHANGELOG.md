<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.5.0

### Features

- Add `c` keyboard action to clear console during `dart run revali dev`

### Enhancements

- Significantly reduce hot reload time
- Print out error message during hot reload when compilation fails, without requiring a full restart

# revali_annotations

## 1.4.1

### Enhancements

- Catch errors when listening to `stdin`

# revali_construct

## 1.8.0

### Features

- Improve hot reload performance
- Debounce changes to slow hot reload frequency
- Pass objects instead of strings to `stderr` to improve communication with `revali`

# revali_core

## 1.4.0

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

<!-- REVALI ROUTER -->

# revali_router

## 3.0.0-dev

### Breaking Changes

- Drop all custom contexts based on lifecycle component
- Create a generic `Context` interface to replace all custom contexts
- Use new types from `revali_router_core`

# revali_router_annotations

## 2.0.0-dev

### Breaking Changes

- Drop `Data` and `Meta` classes
  - Replaced with `AddData` and `MetaData`

# revali_router_core

## 2.0.0-dev

### Breaking Changes

- Drop `DataHandler` and `MetaHandler` classes
  - Replaced with `Data` and `Meta`/`MetaScope`
- Drop `ReadOnly`, `WriteOnly`, and `Mutable` types
  - Replaced with general types

<!-- CONSTRUCTS -->

# revali_server

## 2.0.0-dev

### Breaking Changes

- Support new `AddData` from `revali_router_annotations`
- Support new `MetaData` from `revali_router_annotations`
- Support drop of `ReadOnly`, `WriteOnly`, and `Mutable` from type names

### Enhancements

- Improve logging on errors

<!-- REVALI CLIENT -->

# revali_client

## 1.4.0

### Features

- Support Http Interceptors
- Support clearing single keys from `Storage`

# revali_client_gen

## 1.3.1

### Fixes

- Issue where controllers/methods were not excluded from integrations
- Issue where controllers/methods were not excluded from dependencies
