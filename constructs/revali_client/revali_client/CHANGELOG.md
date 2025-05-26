# CHANGELOG

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
