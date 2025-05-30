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

## 1.4.1

### Enhancements

- Catch errors when listening to `stdin`

# revali_construct

## 1.7.0

### Features

- Add `isEnum` field to `MetaType` class
- Get `fromJson`/`toJson` methods from enum types

# revali_core

## 1.4.0

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

<!-- REVALI ROUTER -->

# revali_router

## 2.3.1

### Enhancements

- Check for closed connection before sending response

# revali_router_annotations

## 1.3.0

### Features

- Coerce dart types from `queryParameters`
- Don't await response handling in `WebSocket`
  - This allows for concurrent message handling

### Enhancements

- Change return type for `Pipe.transform` to `Future<T>`
- Better error handling within WebSockets
- Make WebSocket return values more consistent

### Fixes

- Issue where close reason contained too many characters
- Formats close reason with proper start/end delimiters

# revali_router_core

## 1.9.0

### Features

- Change `queryParameters` & `queryParametersAll` to return `Map<String, dynamic>`
  - Allows for better type coercion
- Update `Binary` type to `List<int>`

<!-- CONSTRUCTS -->

# revali_server

## 1.14.0

### Enhancements

- Clean up `revali_server create pipe` template

### Features

- Support `enum` serialization/deserialization
  - Uses `toJson`/`fromJson` methods if available
  - Defaults to `name`

### Fixes

- Issue where `@Data` annotations were attempting to de-serialize values
- Issue where `@Data` annotations were lost when type was nullable
- Issue where constructor default values were not being set
- Issue where fields were not being utilized within generated lifecycle component classes
- AOT compilation error when a `Pipe` returns a nullable type when the parameter requires a non-nullable type
  - Provides the default value defined in the parameter

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
