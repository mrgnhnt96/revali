---
title: Headers
description: Headers sent by the client to provide additional information
---

# Request Headers

Headers can be used to send information about the request, the client, and more.

## Read-Only

The request headers are read-only and cannot be modified. This is by design, as the headers should be read-only to ensure that the request is not tampered with.

## Accessing the Headers

### Via Context

The headers of the request can be accessed through the `request` property in the context of the Lifecycle Components.

```dart
final headers = context.request.headers;
```

:::tip
Read more about the [Lifecycle Component's context][lifecycle-context].
:::

### Via Binding

The headers of the request can be accessed via the lifecycle method or controller's endpoint by adding the `ReadOnlyHeaders` parameter.

```dart
@Get()
Future<void> helloWorld(
    Header() final String headerName,
) async {
    ...
}
```

:::note
You can use `ReadOnlyHeaders` to access all the headers sent by the client, but it's recommended to use `Header` to access specific headers.
:::

:::tip
Read more about the [Lifecycle Components][lifecycle-components].
:::

[lifecycle-components]: ../lifecycle-components/overview.md
[lifecycle-context]: ../context/overview.md
