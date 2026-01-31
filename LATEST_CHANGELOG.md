<!-- markdownlint-disable MD024 -->

# Latest Changelog

<!-- REVALI -->

# revali

## 2.0.4

### Fixes

- Issue where stdin would error when trying to listen for input during hot reload
- Issue where if exception were thrown on the first server creation, revali would exit
- Prints error messages when exceptions are thrown during server creation

# revali_annotations

## 2.0.2

### Chore

- Sync package versions

# revali_construct

## 2.0.3

### Enhancements

- Prints error messages when exceptions are thrown during server creation

# revali_core

## 1.4.0

### Features

- Create `Args` class to parse arguments from `dart run revali dev`

<!-- REVALI ROUTER -->

# revali_router

## 3.0.3

### Enhancements

- Add optional param to `headers.set(expose: true)` to expose the header to the client

# revali_router_annotations

## 2.0.2+1

### Fix

- Dependencies

# revali_router_core

## 2.0.3

### Enhancements

- Add optional param to `headers.set(expose: true)` to expose the header to the client

<!-- CONSTRUCTS -->

# revali_server

## 2.0.3

### Features

- Add `Body` and `PayloadBody` to inferred types

### Enhancements

- Improve error message when inferred type fails to resolve
- Print stack trace when resolving routes throws

<!-- REVALI CLIENT -->

# revali_client

## 2.0.3

### Enhancements

- Add ability to update headers from within request interceptors

# revali_client_gen

## 2.0.2

### Chore

- Sync package versions
