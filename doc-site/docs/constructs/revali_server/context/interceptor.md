---
title: Interceptor
---

# Interceptor Context

The `Interceptor` Lifecycle Component is used to intercept a request before it reaches the endpoint. This context can be used to manage data attached to the context, get meta data, and more.

:::tip
Learn more about the `Interceptor` Lifecycle Component [here](../lifecycle-components/interceptors).
:::

## Specific Properties

The `InterceptorContext` does not have any specific properties.

### Pre

The `Response` object is "restricted" in `pre`, meaning that you won't be able to set the status code. This is by design, as the status code should be set in the `Interceptor.post` method.

### Post

The `Response` is fully mutable in the `post` method, meaning that you can set the status code, headers, and body.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler](./core/data_handler) object.

### `meta`

The `meta` property is a read-only property for the [MetaHandler](./core/meta_handler) object.

### `request`

The `request` property is a read-only property for the [Request](../request/overview) object.

### `response`

The `response` property is a mutable (restricted) property for the [Response](../response/overview) object.

### `reflect`

The `reflect` property is a read-only property for the [Reflect](./core/reflect) object.
