# CHANGELOG

## 3.0.0 | 08.04.26

### Breaking Changes

- Merge `revali_router_annotations` into this package (that package is deprecated). `@Query`, `@Param`, `@Header`, `@Cookie`, `@Ip`, `@Guards`, `@Middlewares`, `@Wrappers`, `@Intercepts`, `@Combines`, `@AddData`, `@MetaData`, `@SetHeader`, `@StatusCode`, `@Catches`, `@Dep`, `@Binds`, `Bind`, `Pipe`, `RequestHeaders`/`ResponseHeaders`, `RequestCookies`/`ResponseCookies`, and `LifecycleComponent`/`LifecycleComponents` now live here.
- Depend on `revali_core: ^2.0.0`.
- `AllowOrigins`, `PreventHeaders`, and `ExpectHeaders` now live in `revali_core`; still re-exported here for compatibility.

## 2.0.2 | 11.22.25

### Chore

- Sync package versions

## 2.0.2-dev | 10.15.25

### Fix

- Dependencies

## 2.0.0-dev | 10.15.25

### Breaking Changes

- Remove `ExpectHeaders`
- Add `PreventHeaders`

## 1.4.1 | 05.08.25

### Enhancements

- Catch errors when listening to `stdin`

## 1.4.0 | 04.15.25

### Features

- Create `InstanceType` enum to specify the type of instance for a `Controller`

## 1.3.0 | 03.24.25

### Features

- Create `Inject` class to resolve types at runtime and compile-time

### Enhancements

- Add new constructor `WebSocket.mode`

## 1.2.0 | 11.21.24

### Features

- Create `ExpectHeaders` annotation
- Add new `common` constructor for `AllowHeaders`

## 1.1.0 | 11.18.24

### Features

- Create `SSE` annotation for Server-Sent Events

## 1.0.0 | 11.14.24

- Initial Release
