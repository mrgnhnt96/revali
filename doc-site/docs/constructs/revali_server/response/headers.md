---
title: Headers
description: Headers to send additional information to the client
---

# Response Headers

Headers are used to send additional information to the client. Headers can be used to send information about the response, the server, and more. Headers are sent with the response and are used by the client to determine how to handle the response.

## Default Headers

Revali Server does a lot of the heavy lifting for you when it comes to headers.

### Content-Type

This value is based on the type of the response body. For example, if the body is a `String`, the `Content-Type` will be `text/plain`.

### Content-Length

Dart will automatically set the `Content-Length` header for you, so you don't need to set it unless you want to _always_ ensure that the content is the length you specify.

:::caution
When the `Content-Length` header is set and the actual content length is different, the server could throw an exception and the client would receive an error response.
:::

## Setting Headers

### Via Context

The `Response` object can be accessed through the `response` property in the context of the Lifecycle Components.

```dart
context.response.headers['Cache-Control'] = 'no-cache';
```

:::tip
Read more about the [Lifecycle Component's context][lifecycle-context].
:::

### Via Annotations

You can statically set headers using the `@SetHeader` annotation.

```dart
@Get()
@SetHeader('Cache-Control', 'no-cache')
Future<String> helloWorld() async {
    ...
}
```

:::tip
Use [`HttpHeaders`][http-headers] from the dart sdk to avoid using magic strings.
:::

### Via Binding

The `Response` object can be accessed via the controller's endpoint by adding the `Response` parameter to the endpoint method.

```dart
@Get()
Future<void> helloWorld(
    MutableResponse response,
) async {
    response.headers['Cache-Control'] = 'no-cache';
}
```

:::warning
Using the `MutableResponse` parameter in the endpoint method is not recommended. Use the `context` from Lifecycle Components to access the response.

By avoiding the `MutableResponse` parameter, you can keep your endpoint methods clean, focused, and testable.
:::

## Header Annotations

Revali Server provides a few annotations to quickly set headers.

### `@StatusCode`

The `@StatusCode` annotation is used to set the status code of the response.

```dart
@Get()
@StatusCode(201)
Future<void> saveData() async {
    ...
}
```

[lifecycle-context]: ../context/overview.md
[http-headers]: https://api.dart.dev/stable/3.5.3/dart-io/HttpHeaders-class.html
