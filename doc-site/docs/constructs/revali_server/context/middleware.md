---
title: Middleware
---

# Middleware Context

The `Middleware` Lifecycle Component is used to modify the request or response before it reaches the endpoint. This context can be used to manage data attached to the context, get meta data, and more.

:::tip
Learn more about the `Middleware` Lifecycle Component [here](../lifecycle-components/middleware).
:::

## Specific Properties

The `MiddlewareContext` does not have any specific properties.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler](./core/data_handler) object.

### `request`

The `request` property is a mutable property for the [Request](../request/overview) object.

### `response`

The `response` property is a mutable (restricted) property for the [Response](./core/response) object.
