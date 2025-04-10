# CHANGELOG

## 1.3.0 | 04.09.25

### Features

- Add `registerLazySingleton` and `registerFactory` methods to `DI` interface
  - This is to support `factories`, so that dependencies can be re-created each time they are resolved

### Future BREAKING Changes

- `DI.register` will be removed in favor of `registerLazySingleton` and `registerFactory`
- `DI.registerInstance` will be removed in favor of `registerSingleton`

## 1.2.0 | 01.18.25

### Enhancements

- Require `Object` type for `DI` registrations

## 1.1.0 | 12.11.24

### Features

- Abstract `DI` class to support creating own instances of `DI`
- Create `DIHandler` to override dependency registry during server startup
- Add `initializeDI` method to support creating own instances of `DI`

## 1.0.0 | 11.14.24

- Initial Release
