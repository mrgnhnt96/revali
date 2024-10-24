---
title: Middleware
---

# Middleware Context

The `Middleware` Lifecycle Component is used to modify the request or response before it reaches the endpoint. This context can be used to manage data attached to the context, get meta data, and more.

:::tip
Learn more about the `Middleware` Lifecycle Component [here][middleware].
:::

## Specific Properties

The `MiddlewareContext` does not have any specific properties.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler][data_handler] object.

### `request`

The `request` property is a mutable property for the [Request][request] object.

### `response`

The `response` property is a mutable (restricted) property for the [Response][response] object.

[middleware]: ../lifecycle-components/2-middleware.md
[data_handler]: ./core/data_handler.md
[request]: ../request/index.md
[response]: ../response/index.md
