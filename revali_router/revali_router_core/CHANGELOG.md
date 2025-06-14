# CHANGELOG

## 1.9.0 | 05.08.25

### Features

- Change `queryParameters` & `queryParametersAll` to return `Map<String, dynamic>`
  - Allows for better type coercion
- Update `Binary` type to `List<int>`

## 1.8.1 | 04.15.25

### Enhancements

- Wrap clean up functions in `try/catch` to avoid unhandled exceptions

## 1.8.0 | 04.07.25

### Features

- Add `MutableBody` getter to `MutableRequest`

### Enhancements

- Create `AsyncWebSocketSender` interface to send messages asynchronously

## 1.7.0 | 03.26.25

### Features

- Create `CloseWebSocket` class to manually close a `WebSocket`
- Create `WebSocketContext` class for context management of `WebSocket` connections
- Add `code` and `reason` params to `MutableWebSocketRequest.close`

## 1.6.0 | 03.24.25

### Features

- Support for `Cookie` param

### Enhancements

- Change return type of `MutableBody.replace` method to `Future<void>`

## 1.5.1 | 02.08.25

### Chores

- Upgrade dependencies

## 1.5.0 | 01.27.25

### Features

- Create `CleanUp` class to handle cleanup of resources after request handling
- Add `cleanUp` method to `BodyData` to handle cleanup

## 1.4.0 | 01.20.25

### Features

- Create cookie interfaces for managing cookies
  - `MutableCookies`
  - `ReadOnlyCookies`
  - `MutableSetCookies`
  - `ReadOnlySetCookies`

## 1.3.0 | 12.11.24

### Features

- Create `BaseContext` to merge contexts between all components
- Create Result type for:
  - Interceptor (pre and post)
- Use new `Meta` types

### Enhancements

- Simplify Results for:
  - Exception Catcher
  - Guard
- Require type argument on `ExceptionCatcher` and `ExceptionCatcherResult`
- Rename Guard Result constructors to `pass` and `block`
- Rename Exception Catcher Result constructors to `handled` and `unhandled`

## 1.2.0 | 11.21.24

### Features

- Create `ExpectedHeaders` as non-optional headers to be passed into the request
- Add `ExpectedHeaders` to lifecycle components

## 1.1.0 | 11.18.24

### Features

- Create `ResponseHandler` interface
  - A `ResponseHandler` is a advanced handler that can be provided to a route to send the response to the client differently

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
