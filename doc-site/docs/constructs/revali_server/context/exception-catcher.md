---
title: Exception Catcher
description: Properties and methods available in the Exception Catcher context
---

# Exception Catcher Context

The `Exception Catcher` Lifecycle Component allows you to catch exceptions that are thrown during the request lifecycle. This context can be used to manage data attached to the context, get meta data, and more.

:::tip
Learn more about the `Exception Catcher` Lifecycle Component [here][exception-catchers].
:::

## Specific Properties

The `ExceptionCatcherContext` does not have any specific properties.

## General Properties

### `data`

The `data` property is a mutable property for the [DataHandler][data_handler] object.

### `meta`

The `meta` property is a detailed read-only (`ReadOnlyMetaDetailed`) property for the [MetaHandler][meta_handler] object.

### `meta.route`

Details for the `RouteEntry` that the request is currently executing.

| Property | Type | Description |
| --- | --- | --- |
| `path` | `String` | The path of the route |
| `method` | `String` | The HTTP method of the route |
| `fullPath` | `String` | The full path of the route |
| `parent` | `RouteEntry` | The parent route of the route |

### `request`

The `request` property is a read-only property for the [Request][request] object.

### `response`

The `response` property is a mutable (restricted) property for the [Response][response] object.

[exception-catchers]: ../lifecycle-components/advanced/exception-catchers.md
[data_handler]: ./core/data_handler.md
[meta_handler]: ./core/meta_handler.md
[request]: ../request/overview.md
[response]: ../response/overview.md
