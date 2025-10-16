# CHANGELOG

## 3.0.0+2-dev | 10.15.25

### Fix

- Dependencies

## 3.0.0+1-dev | 10.15.25

### Fix

- Payload byte length calculation

## 3.0.0-dev | 09.19.25

### Breaking Changes

- Drop all custom contexts based on lifecycle component
- Create a generic `Context` interface to replace all custom contexts
- Use new types from `revali_router_core`

## 2.4.1 | 08.26.25

### Fixes

- Issue where allowed headers were not inherited properly
- Issue where allowed headers could block requests with unknown headers

## 2.4.0 | 08.16.25

### Features

- Create new `add` method to `MutableCookies`
- Add clean up to router close method to prevent memory leaks

## 2.3.1 | 05.30.25

### Enhancements

- Check for closed connection before sending response

## 2.3.0 | 05.08.25

### Enhancements

- Binary serialization/deserialization

## 2.2.1 | 04.16.25

### Enhancements

- Catch errors when sending data over the web socket

## 2.2.0 | 04.15.25

### Features

- Create `kDebugMode`, `kProfileMode`, and `kReleaseMode` constants

## 2.1.1 | 04.09.25

### Fixes

- Issue where resolving the payload would hang on a web socket message

## 2.1.0 | 04.07.25

### Features

- Explicitly check for binary types when resolving body
- Clean up resources after response has been handled
- Support sending data asynchronously
  - As opposed to only on an event received

### Enhancements

- Check for `null` values in addition to `NullBody` body data types
- Handle exceptions when resolving body
- Coerce body types when no mime type is provided
- Improve path parameter extraction
- Force sequential execution of sent `WebSocket` messages

### Fixes

- Issue where crash would occur during SSE when connection was closed by client unexpectedly
- Issue where endpoint path would result in 404 when parent controller's path was empty

## 2.0.1 | 03.26.25

### Fixes

- Issue where `WebSocket` would only send the first message

### Features

- Create `WebSocketContext` class for context management of `WebSocket` connections
  - Specifically `close`ing the connection
- Allow empty paths for parent routes when their handler has not been set

## 2.0.0 | 03.26.25

### Breaking Changes

- Remove `UnknownBodyData`, will default to a `ByteStreamBodyData` instead
  - `UnknownBodyData` had the potential to hang if the body was a open stream

### Features

- Create `WebSocketContext` class for context management of `WebSocket` connections
  - Specifically `close`ing the connection
- Allow empty paths for parent routes when their handler has not been set

## 1.7.0 | 03.24.25

### Features

- Add support for primitive body types
  - `int`, `double`, `bool`

### Enhancements

- Clean up resources after request is complete

### Fixes

- Issue where streamed responses were not encoded correctly
- Issue where body could throw exception during `set`ting
  - Now catches and sets status code to 500
- Issue where on connect was not being called for `WebSocket`

## 1.6.1 | 02.08.25

### Chores

- Upgrade dependencies

## 1.6.0 | 02.07.25

### Features

- Use `.then` syntax instead of await to handle request operation
  - This allows for faster request handling

## 1.5.0 | 01.27.25

### Enhancements

- `ByteStreamBodyData` now extends `StreamBodyData`
- Improve server sent event response handling
  - close stream when client disconnects
  - Use new `CleanUp` class to handle cleanup

### Features

- Add `CleanUp` class to `DataHandler` on initialization

## 1.4.1 | 01.27.25

### Enhancements

- Handling responses and root errors

### Fixes

- Poor type handling for header values that could cause a response to fail

## 1.4.0 | 01.20.25

### Features

- Manage cookies with `Headers.cookies` and `Headers.setCookies`

## Features | 01.20.25

- Manage cookies with `Headers.cookies` and `Headers.setCookies`

## 1.3.0 | 12.11.24

### Features

- Combine meta types for better polymorphism support
- Add `ReadOnlyMeta` to `MiddlewareContext`

### Enhancements

- Rename `ReadOnlyDataHandler` to `ReadOnlyData`
- Rename `WriteOnlyDataHandler` to `WriteOnlyData`

### Fixes

- Issue where routes would not appear in list of routes after server restart

## 1.2.0 | 11.21.24

### Features

- Create `ExpectedHeaders` as non-optional headers to be passed into the request
- Add `ExpectedHeaders` to access control headers

### Enhancements

- Re-order the pre-request checks to
  - CORs Origins Validation
  - CORs Headers Validation
  - (CORs) Expected Headers Validation
  - Options Request Handling
  - Redirect Handling
- Return actual response in the `OPTIONS` request instead of a canned response
- Handle internal root errors with the response handler instead of deprecated `send` method

### Fix

- Add `routes` param to `SseRoute` constructor

## 1.1.0 | 11.18.24

### Features

- Support advanced `ResponseHandler` per route
  - If a response needs to be handled differently for a specific route, a `ResponseHandler` can be provided to the route to send the response to the client
- Create default response handler for `Router`
- Create `SseRoute` for Server-Sent Events
- Create `SseResponseHandler` for Server-Sent Events

### Enhancements

- Improve how streams are prepared for sending to the client

### Chores

- Upgrade dependencies

## 1.0.0 | 11.14.24

- Initial Release
