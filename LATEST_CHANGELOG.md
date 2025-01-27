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

## 1.4.1

### Enhancements

- Handling responses and root errors

### Fixes

- Poor type handling for header values that could cause a response to fail

# revali_router_annotations

## 1.1.0

### Features

- Add `LifecycleComponent` annotation to support creating lifecycle components using classes
- Add `LifecycleComponents` annotation to support registering multiple lifecycle components via type referencing

# revali_router_core

## 1.4.0

### Features

- Create cookie interfaces for managing cookies
  - `MutableCookies`
  - `ReadOnlyCookies`
  - `MutableSetCookies`
  - `ReadOnlySetCookies`

<!-- CONSTRUCTS -->

# revali_server

## 1.6.0

### Enhancements

- Remove use of deprecated apis
- Create extensions to get fromJson constructor and import paths

### (Future) Breaking Changes

- Deprecate `ServerParam.typeImport` in favor of `ServerParam.type.importPath`

### Features

- Create new factory constructors for `ServerImports` to better handle extracting import paths
- Create `ServerType` class to reflect `MetaType` for method parameter types
- Leverage `hasFromJsonConstructor` to convert body/header/param/query request values
