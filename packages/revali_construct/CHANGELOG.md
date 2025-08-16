# CHANGELOG

## 1.8.0 | 08.16.25

### Features

- Improve hot reload performance
- Debounce changes to slow hot reload frequency
- Pass objects instead of strings to `stderr` to improve communication with `revali`

## 1.7.0 | 05.08.25

### Features

- Add `isEnum` field to `MetaType` class
- Get `fromJson`/`toJson` methods from enum types

## 1.6.0 | 04.15.25

### Features

- Add `InstanceType type` parameter to `@Controller` annotation

## 1.5.0 | 04.07.25

### Features

- Create `MetaToJson` class to provide details about `toJson` methods

## 1.4.0 | 03.26.25

### Features

- Create `MetaFromJson` class to improve support for `fromJson` factory/static methods
- Resolve `fromJson` static methods within types

### Breaking Changes (future)

- Deprecate `hasFromJsonConstructor` in `MetaType`
  - Use `hasFromJson` instead

## 1.3.0 | 03.24.25

### Features

- Create classes to support records

### Enhancements

- Remove type argument from `RevaliDirectory`
- Merge `MetaReturnType` into `MetaType`

## 1.2.1 | 02.08.25

### Chores

- Upgrade dependencies

## 1.2.0 | 01.27.25

### Features

- Create class `MetaType` for method parameter types

## 1.1.1 | 12.11.24

### Enhancements

- Add assertion checks for `DartFile` to ensure that part directives are unique

## 1.1.0 | 11.18.24

### Features

- Support `SSE` methods

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
