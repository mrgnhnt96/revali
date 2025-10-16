# CHANGELOG

## 2.0.2-dev | 10.15.25

### Fix

- Dependencies

## 2.0.1+1-dev | 10.15.25

### Fix

- Dependencies

## 2.0.1-dev | 09.19.25

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

### Enhancements

- Improve logging on errors

## 2.0.0-dev | 09.19.25

### Breaking Changes

- Support new `AddData` from `revali_router_annotations`
- Support new `MetaData` from `revali_router_annotations`
- Support drop of `ReadOnly`, `WriteOnly`, and `Mutable` from type names

### Enhancements

- Improve logging on errors

## 1.15.0 | 08.18.25

### Features

- Pass in `router.close` to `handleRequests` to allow for clean up of resources

## 1.14.0 | 05.08.25

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

## 1.13.0 | 04.15.25

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

## 1.12.1 | 04.09.25

### Enhancements

- Handle `dynamic` types when accessing the data from the request

## 1.12.0 | 04.07.25

### Features

- Support default arguments for parameters

### Enhancements

- Clean up argument generation for methods
- Clean up class parsing from analyzed files

## 1.11.2 | 03.27.25

### Fixes

- Issue where arguments were not passed properly to class from type references

## 1.11.1 | 03.27.25

### Enhancements

- Add check to ensure controller names are unique

### Fixes

- Issue where lifecycle components that didn't exist would be generated

## 1.11.0 | 03.26.25

### Features

- Support empty paths for `Controller`s
- Support `fromJson` resolution for static methods within return types
- Create `CloseWebSocket` class to manually close a `WebSocket`
  - [docs](https://www.revali.dev/constructs/revali_server/response/websockets#closing-the-connection)

### Fixes

- Prepend (generated) route & file name with `r` + index when the `Controller`'s path is empty
- Type resolution when converting dynamic types to `Map` within a `fromJson` call

### Enhancements

- Create `ServerFromJson` class to match change from `revali_construct`

## 1.10.1 | 03.24.25

### Features

- Support for `Cookie` param
- Support for generic types in `LifecycleComponent`
- Support `Inject` types in annotations
  - Allows for constant resolution of annotations that require dependency injection and need arguments
- Support record types

## 1.10.0 | 03.24.25

### Features

- Support for `Cookie` param
- Support for generic types in `LifecycleComponent`
- Support `Inject` types in annotations
  - Allows for constant resolution of annotations that require dependency injection and need arguments
- Support record types

## 1.9.5 | 02.08.25

### Fix

- Issue where dependency injection was not setup correctly during build mode

## 1.9.4 | 02.08.25

### Chore

- Upgrade dependencies
- Fix breaking changes

## 1.9.3 | 02.08.25

### Chore

- Upgrade dependencies

## 1.9.2 | 02.08.25

### Chore

- Upgrade dependencies

### Fixes

- [CLI] Issue where controller name was not being set correctly during file creation

## 1.9.0 | 02.08.25

### Chore

- Upgrade dependencies

### Fixes

- [CLI] Issue where controller name was not being set correctly during file creation

## 1.9.1 | 02.07.25

### Fixes

- [CLI] Issue where controller name was not being set correctly during file creation

## 1.9.0 | 02.07.25

### Fixes

- [CLI] Issue where controller name was not being set correctly during file creation

## 1.8.0 | 01.29.25

### Features

- Create CLI to generate components

## 1.7.0 | 01.27.25

### Features

- Create inferred param for `CleanUp` class for

## 1.6.0 | 01.27.25

### Enhancements

- Remove use of deprecated apis
- Create extensions to get fromJson constructor and import paths

### (Future) Breaking Changes

- Deprecate `ServerParam.typeImport` in favor of `ServerParam.type.importPath`

### Features

- Create new factory constructors for `ServerImports` to better handle extracting import paths
- Create `ServerType` class to reflect `MetaType` for method parameter types
- Leverage `hasFromJsonConstructor` to convert body/header/param/query request values

## 1.5.1 | 01.22.25

### Fixes

- Change observer list from constant

### Features

- Add support for Cookies access
  - `MutableCookies`
  - `ReadOnlyCookies`
  - `MutableSetCookies`
  - `ReadOnlySetCookies`

## 1.5.0 | 01.20.25

### Features

- Add support for Cookies access
  - `MutableCookies`
  - `ReadOnlyCookies`
  - `MutableSetCookies`
  - `ReadOnlySetCookies`

## 1.4.1 | 01.18.25

### Fixes

- Issue retrieving nested values from the body of a request

## 1.4.0 | 01.18.25

### Enhancements

- Support new requirement for `DI` registrations to be of type `Object`
- Wrap `DI` with handler _after_ configuration is complete

## 1.3.0 | 12.11.24

### Features

- Create Lifecycle Components using classes to support use of binding logic
- Support `initializeDI` method to create own instances of `DI`

## 1.2.0 | 11.21.24

### Features

- Support `expectedHeaders` argument
- Allow multiple `AllowedHeaders`, `AllowedOrigins` and `ExpectedHeaders` to be provided on a single route/controller

## 1.1.0 | 11.18.24

### Features

- Support `ResponseHandler` annotations
- Support `SSE` annotation

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
