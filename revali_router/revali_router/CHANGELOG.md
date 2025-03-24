# CHANGELOG

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
