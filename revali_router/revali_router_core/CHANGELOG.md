# CHANGELOG

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
