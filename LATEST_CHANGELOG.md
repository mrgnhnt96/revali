<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.2.0

### Features

- Add abbreviation for dart define (`-D`) to match dart's CLI for `build` and `dev` commands
- Safely close the server when `CTRL+C` is pressed
- Watch `components` directory within the `lib` directory for changes to reload the server

### Enhancements

- Lower min bound for Dart SDK to `3.4.0`
- Improve error handling and logs for server startup

# revali_annotations

## 1.2.0

### Features

- Create `ExpectHeaders` annotation
- Add new `common` constructor for `AllowHeaders`

# revali_construct

## 1.1.1

### Enhancements

- Add assertion checks for `DartFile` to ensure that part directives are unique

# revali_core

## 1.2.0

### Enhancements

- Require `Object` type for `DI` registrations

<!-- REVALI ROUTER -->

# revali_router

## 1.3.0

### Features

- Combine meta types for better polymorphism support
- Add `ReadOnlyMeta` to `MiddlewareContext`

### Enhancements

- Rename `ReadOnlyDataHandler` to `ReadOnlyData`
- Rename `WriteOnlyDataHandler` to `WriteOnlyData`

### Fixes

- Issue where routes would not appear in list of routes after server restart

# revali_router_annotations

## 1.1.0

### Features

- Add `LifecycleComponent` annotation to support creating lifecycle components using classes
- Add `LifecycleComponents` annotation to support registering multiple lifecycle components via type referencing

# revali_router_core

## 1.3.0

### Features

- Create `BaseContext` to merge contexts between all components
- Create Result type for:
  - Interceptor (pre and post)
- Use new `Meta` types

### Enhancements

- Simplify Results for:
  - Exception Catcher
  - Guard
- Require type argument on `ExceptionCatcher` and `ExceptionCatcherResult`
- Rename Guard Result constructors to `pass` and `block`
- Rename Exception Catcher Result constructors to `handled` and `unhandled`

<!-- CONSTRUCTS -->

# revali_server

## 1.4.0

### Enhancements

- Support new requirement for `DI` registrations to be of type `Object`
- Wrap `DI` with handler _after_ configuration is complete
