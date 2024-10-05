---
title: Bind
---

# Bind Context

The `Bind` lifecycle component is used to bind a value from the request to a parameter. This context can be used to get insights into the binding call, data, meta data, and more.

:::tip
Learn more about the `Bind` lifecycle component [here](../core/binding).
:::

## Specific Properties

### `nameOfParameter`

This property is used to get the name of the parameter that is being bound.

```dart
void helloWorld(
    @UserBind() User user,
)
```

In the above example, the `nameOfParameter` will return `user`.

### `parameterType`

This property is used to get the type of the parameter that is being bound.

```dart
void helloWorld(
    @UserBind() User user,
)
```

In the above example, the `parameterType` will return the `User` type.

## General Properties

### `data`

The `data` property is a read-only property for the [DataHandler](./core/data_handler) object.

### `meta`

The `meta` property is a read-only property for the [MetaHandler](./core/meta_handler) object.

### `request`

The `request` property is a read-only property for the [Request](./core/request) object.

### `response`

The `response` property is a read-only property for the [Response](./core/response) object.
