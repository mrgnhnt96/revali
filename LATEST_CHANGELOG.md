<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.4.2

### Enhancements

- Add support for extracting `InstanceType` from `@Controller`
- Get next available port for `dart-vm-service-port` instead of using a set port
- Support `kDebugMode`, `kProfileMode`, and `kReleaseMode`
  - Corresponds to `--debug`, `--profile`, and `--release` flags

### Features

- Support passing arguments to `dart run revali dev`
  - Example: `dart run revali dev -- --some-flag`

# revali_annotations

## 1.4.0

### Features

- Create `InstanceType` enum to specify the type of instance for a `Controller`

# revali_construct

## 1.6.0

### Features

- Add `InstanceType type` parameter to `@Controller` annotation

# revali_core

## 1.4.0

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

<!-- REVALI ROUTER -->

# revali_router

## 2.2.1

### Enhancements

- Catch errors when sending data over the web socket

# revali_router_annotations

## 1.3.0

### Enhancements

- Change return type for `Pipe.transform` to `Future<T>`

# revali_router_core

## 1.8.1

### Enhancements

- Wrap clean up functions in `try/catch` to avoid unhandled exceptions

<!-- CONSTRUCTS -->

# revali_server

## 1.13.0

### Features

- Support changing the `Controller` instance type from `singleton` to `factory

```dart
@Controller('', type: InstanceType.factory)
class MyController {}
```

### Enhancements

- Improve type formatting when creating `Pipe` files using `revali_server create pipe` cli

### Breaking (Lil' one tho)

- Change return type from `FutureOr` to `Future` for `Pipe.transform`

<!-- REVALI CLIENT -->

# revali_client

## 1.2.0

### Features

- Add `server_name` option to `revali.yaml#constructs.revali_client` to set the name of the server class

### Enhancements

- Add check for empty query parameters before appending `?` to the URL
- Remove `final` keyword from generated server class

### Fixes

- Issue where `@ExcludeFromClient` was being ignored for interface methods
- Issue where empty controller paths would result in `//<path>` being generated in the client

# revali_client_gen

## 1.2.1

### Fixes

- Swallow errors when connection is lost
