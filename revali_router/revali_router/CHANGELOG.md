# CHANGELOG

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
