# CHANGELOG

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
