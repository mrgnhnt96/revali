---
title: Guard
description: Properties and methods available in the Guard context
---

# Guard Context

The `Guard` Lifecycle Component is used to guard a route from being accessed. This context can be used to manage data attached to the context, get meta data, and more.

:::tip
Learn more about the `Guard` Lifecycle Component [here][guards].
:::

## Specific Properties

The `GuardContext` does not have any specific properties.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler][data_handler] object.

### `meta`

The `meta` property is a read-only property for the [MetaHandler][meta_handler] object.

### `request`

The `request` property is a read-only property for the [Request][request] object.

### `response`

The `response` property is a mutable (restricted) property for the [Response][response] object.

[guards]: ../lifecycle-components/guards.md
[data_handler]: ./core/data_handler.md
[meta_handler]: ./core/meta_handler.md
[request]: ../request/overview.md
[response]: ../response/overview.md
