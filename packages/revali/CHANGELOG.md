# CHANGELOG

## 2.0.0-dev | 09.19.25

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

## 1.5.0 | 08.16.25

### Features

- Add `c` keyboard action to clear console during `dart run revali dev`

### Enhancements

- Significantly reduce hot reload time
- Print out error message during hot reload when compilation fails, without requiring a full restart

## 1.4.2 | 04.15.25

### Enhancements

- Add support for extracting `InstanceType` from `@Controller`
- Get next available port for `dart-vm-service-port` instead of using a set port
- Support `kDebugMode`, `kProfileMode`, and `kReleaseMode`
  - Corresponds to `--debug`, `--profile`, and `--release` flags

### Features

- Support passing arguments to `dart run revali dev`
  - Example: `dart run revali dev -- --some-flag`

## 1.4.1 | 04.07.25

### Enhancements

- Print `GET (SSE)` when using `@SSE` methods

## 1.4.0 | 03.24.25

### Enhancements

- Improve and clean up `MetaType` resolution
- Safely retrieve constructor from the controller

### Features

- Add (hidden) `--generate-only` flag to `dev` command
- Support for `workspace`s in `pubspec.yaml`

### Fixes

- Add `--profile` flag to `dev` (runner) command

## 1.3.3 | 02.08.25

### Chores

- Upgrade dependencies
- Fix breaking changes

## 1.3.2 | 02.08.25

### Chores

- Upgrade dependencies

## 1.3.1 | 02.08.25

### Chores

- Upgrade dependencies

## 1.3.0 | 01.27.25

### Features

- Create new class for `Type`s on method parameters
  - Add property `hasFromJsonConstructor`

### Enhancements

- Clean up import path retrieval

## 1.2.0 | 12.11.24

### Features

- Add abbreviation for dart define (`-D`) to match dart's CLI for `build` and `dev` commands
- Safely close the server when `CTRL+C` is pressed
- Watch `components` directory within the `lib` directory for changes to reload the server

### Enhancements

- Lower min bound for Dart SDK to `3.4.0`
- Improve error handling and logs for server startup

## 1.1.1 | 11.20.24

### Chores

- Upgrade dependencies
- Clean up lint warnings

## 1.1.0 | 11.18.24

### Features

- Support `SSE` methods

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
