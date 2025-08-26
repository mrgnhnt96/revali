<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 1.5.0

### Features

- Add `c` keyboard action to clear console during `dart run revali dev`

### Enhancements

- Significantly reduce hot reload time
- Print out error message during hot reload when compilation fails, without requiring a full restart

# revali_annotations

## 1.4.1

### Enhancements

- Catch errors when listening to `stdin`

# revali_construct

## 1.8.0

### Features

- Improve hot reload performance
- Debounce changes to slow hot reload frequency
- Pass objects instead of strings to `stderr` to improve communication with `revali`

# revali_core

## 1.4.0

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

<!-- REVALI ROUTER -->

# revali_router

## 2.4.1

### Fixes

- Issue where allowed headers were not inherited properly
- Issue where allowed headers could block requests with unknown headers

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

## 1.9.1

### Features

- Create `add` method to `MutableCookies`

<!-- CONSTRUCTS -->

# revali_server

## 1.15.0

### Features

- Pass in `router.close` to `handleRequests` to allow for clean up of resources

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
