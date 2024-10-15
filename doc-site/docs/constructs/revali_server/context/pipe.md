---
title: Pipe
---

# Pipe Context

A `Pipe` is a used to transform a [binding](../core/binding) from the original type to another type to be delivered to the endpoint. This context can be used to get insights into the pipe call, data, meta data, and more.

:::tip
Learn more about the `Pipe` lifecycle component [here](../core/pipes).
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

- [body](../core/binding#body)
- [data](../core/binding#data)
- [query](../core/binding#query)
- [queryAll](../core/binding#all-values)
- [param](../core/binding#param)
- [bind](../core/binding#bind)
- [binds](../core/binding#via-binds)
- [header](../core/binding#header)
- [headerAll](../core/binding#all-values-1)

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

The `data` property is a mutable property for the [DataHandler](./core/data_handler) object.

### `meta`

The `meta` property is a mutable (restricted) property for the [Meta](./core/meta_handler)
