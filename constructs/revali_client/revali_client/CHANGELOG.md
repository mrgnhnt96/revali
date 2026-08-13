# CHANGELOG

## 2.1.0 | 08.13.26

### Features

- Send streamed request bodies. A `Stream<List<int>>` or `Stream<String>` body is now handed to the transport and sent incrementally, so a large upload never has to fit in memory; previously this threw `UnimplementedError`. The server side already worked — `@Body() Stream<List<int>>` reads the payload as it arrives — so this completes the round trip. `HttpRequest` gains `bodyStream`. Any other `Stream<T>` throws an `ArgumentError` naming the supported types rather than inventing a framing format the server has no binding for.

### Fixes

- Parse every `Set-Cookie` value, and stop storing cookie attributes as cookies. A response setting several cookies arrives as one comma-joined header, which `CookieParser` could not match at all, so none were saved; the attributes it did match put `Path` and `Expires` into storage. Splitting now happens only at a comma beginning a new `name=` pair, so the comma inside an `Expires` date cannot split a cookie in half.
- Actually enable cross-origin cookie credentials on web by setting `BrowserClient.withCredentials = true`, instead of adding a literal `credentials: 'include'` HTTP header (a no-op -- `credentials` is a `fetch()`-level option, not a header, so it never did anything). Non-web platforms are unaffected (no browser cookie jar to opt into).

## 2.0.5 | 08.07.26

### Fixes

- Actually enable cross-origin cookie credentials on web by setting `BrowserClient.withCredentials = true`, instead of adding a literal `credentials: 'include'` HTTP header (a no-op -- `credentials` is a `fetch()`-level option, not a header, so it never did anything). Non-web platforms are unaffected (no browser cookie jar to opt into).

## 2.0.4 | 02.18.26

### Enhancements

- Add `credentials: 'include'` to HTTP requests for cookie support with fetch

## 2.0.3 | 01.31.26

### Enhancements

- Add ability to update headers from within request interceptors

## 2.0.2 | 11.22.25

### Chore

- Sync package versions

## 1.4.0 | 05.30.25

### Features

- Support Http Interceptors
- Support clearing single keys from `Storage`

## 1.3.1 | 05.26.25

### Fixes

- Issue where matching types would not be considered equal

## 1.3.0 | 05.08.25

### Features

- Add `server_name` option to `revali.yaml#constructs.revali_client` to set the name of the server class

### Enhancements

- Add `clear` method to `Storage` class
  - Utility method to clear the cookies cache

### Fixes

- Serialize custom types in query parameters

## 1.2.0 | 04.15.25

### Features

- Add `server_name` option to `revali.yaml#constructs.revali_client` to set the name of the server class

### Enhancements

- Add check for empty query parameters before appending `?` to the URL
- Remove `final` keyword from generated server class

### Fixes

- Issue where `@ExcludeFromClient` was being ignored for interface methods
- Issue where empty controller paths would result in `//<path>` being generated in the client

## 1.1.0 | 04.07.25

### Features

- Add `ExcludeFromClient` annotation to exclude controllers/methods from being generated in the client

## 1.0.1 | 03.24.25

Initial Release!

## 1.0.0 | 03.24.25

Initial Release!
