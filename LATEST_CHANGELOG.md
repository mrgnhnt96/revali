<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.0.0-dev

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

# revali_annotations

## 1.4.1

### Enhancements

- Catch errors when listening to `stdin`

# revali_construct

## 2.0.0-dev

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

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

## 2.0.1-dev

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

### Enhancements

- Improve logging on errors

<!-- REVALI CLIENT -->

# revali_client

## 1.4.0

### Features

- Support Http Interceptors
- Support clearing single keys from `Storage`

# revali_client_gen

## 2.0.0-dev

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`
