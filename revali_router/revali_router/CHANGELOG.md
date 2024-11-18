# CHANGELOG

## 1.1.0 | 11.18.24

### Features

- Support low-level `ResponseHandler` per route
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
