# CHANGELOG

## 2.0.2-dev | 10.15.25

### Fix

- Dependencies

## 2.0.0+1-dev | 10.15.25

### Fix

- Dependencies

## 2.0.0-dev | 09.19.25

### Breaking Changes

- Update `analyzer` dependency to `^8.0.0`

## 1.3.1 | 05.30.25

### Fixes

- Issue where controllers/methods were not excluded from integrations
- Issue where controllers/methods were not excluded from dependencies

## 1.3.0 | 05.08.25

### Features

- Support dart `enum` serialization/deserialization
  - Uses `toJson`/`fromJson` methods if available
  - Defaults to `name`

### Fixes

- Issue where null values were being passed as `String` instead of omitted
- Issue where some body keys were being dropped from the request body

## 1.2.1 | 04.16.25

### Fixes

- Swallow errors when connection is lost

## 1.2.0 | 04.07.25

### Features

- Support `ExcludeFromClient` annotation to exclude controllers/methods from being generated in the client
- Support explicit types for `toJson` return types
- Support explicit types for `fromJson` parameters

### Fixes

- Issue where multiple path parameters would malform the generated endpoint path

### Enhancements

- Mark parameters as optional if there is a default value or if the type is nullable

## 1.1.1 | 03.27.25

### Fixes

- Issue where not all imports were being added to the generated code from type's type arguments

## 1.1.0 | 03.26.25

### Enhancements

- Create `ClientFromJson` class to match change from `revali_construct`

## 1.0.1 | 03.24.25

Initial Release!

## 1.0.0 | 03.24.25

Initial Release!
