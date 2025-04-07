# CHANGELOG

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
