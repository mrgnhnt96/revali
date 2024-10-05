---
title: Interceptor
---

# Interceptor Context

The `Interceptor` lifecycle component is used to intercept a request before it reaches the endpoint. This context can be used to manage data attached to the context, get meta data, and more.

:::tip
Learn more about the `Interceptor` lifecycle component [here](../lifecycle-components/interceptors).
:::

## Specific Properties

The `InterceptorContext` does not have any specific properties.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler](./core/data_handler) object.

### `meta`

The `meta` property is a read-only property for the [MetaHandler](./core/meta_handler) object.

### `request`

The `request` property is a read-only property for the [Request](./core/request) object.

### `response`

The `response` property is a mutable (restricted) property for the [Response](./core/response) object.

### `reflect`

The `reflect` property is a read-only property for the [Reflect](./core/reflect) object.
