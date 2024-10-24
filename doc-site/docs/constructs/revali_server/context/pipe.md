---
title: Pipe
---

# Pipe Context

A `Pipe` is used to transform a [binding] from the original type to another type to be delivered to the endpoint. This context can be used to get insights into the: pipe call, data, metadata, and more.

:::tip
Learn more about the `Pipe` Lifecycle Component [here][pipes].
:::

## Specific Properties

### `type`

This property is used to get what kind of annotation is being used to bind the parameter.

```dart
void helloWorld(
    @Body('userId', UserIdPipe) User user,
)
```

In the above example, the `type` will return `AnnotationType.body`.

#### AnnotationType

The available annotation types are:

- [body][binding-body]
- [data][binding-data]
- [query][binding-query]
- [queryAll][binding-all-values]
- [param][binding-param]
- [bind][binding-bind]
- [binds][binding-via-binds]
- [header][binding-header]
- [headerAll][binding-all-values-1]

### `annotationArgument`

This property is used to get the argument passed to the annotation.

```dart
void helloWorld(
    @Body('userId', UserIdPipe) User user,
)
```

In the above example, the `annotationArgument` will return `userId`.

### `nameOfParameter`

This property is used to get the name of the parameter.

```dart
void helloWorld(
    @Body('userId', UserIdPipe) User user,
)
```

In the above example, the `nameOfParameter` will return `user`.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler][data_handler] object.

### `meta`

The `meta` property is a mutable (restricted) property for the [Meta][meta_handler]

[pipes]: ../core/40-pipes.md
[data_handler]: ./core/data_handler.md
[binding]: ../core/20-binding.md
[meta_handler]: ./core/meta_handler.md
[binding-body]: ../core/20-binding.md#body
[binding-data]: ../core/20-binding.md#data
[binding-query]: ../core/20-binding.md#query
[binding-all-values]: ../core/20-binding.md#all-values
[binding-param]: ../core/20-binding.md#param
[binding-bind]: ../core/20-binding.md#bind
[binding-via-binds]: ../core/20-binding.md#via-binds
[binding-header]: ../core/20-binding.md#header
[binding-all-values-1]: ../core/20-binding.md#all-values-1
