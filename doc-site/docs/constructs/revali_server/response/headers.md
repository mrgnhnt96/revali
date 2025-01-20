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
    MutableHeaders headers,
) async {
    headers['Cache-Control'] = 'no-cache';
}
```

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

## Headers Types

In Revali Server, the headers are divided into two types:

- Body Headers
- Response Headers

To get both the body headers and the response headers, you can access the `joinedHeaders` property of the response object.

```dart
final headers = response.joinedHeaders;
```

### Headers from Body

There are certain headers that are derived from the response body. Each body type has its own set of headers that will be joined with the response headers before sending the response to the client. Some examples of body headers are:

- `Content-Type`
- `Content-Length`
- `Transfer-Encoding`
- `Content-Encoding`

To get the body headers, you can access the `headers` property of the response's body object.

```dart
final headers = response.body.headers;
```

### Headers from Response

The response headers are generally set throughout the lifecycle of the request. These headers are set by the server and can be modified by the user. Some examples of response headers are:

- `Date`
- `Cache-Control`
- `Cookie`

[lifecycle-context]: ../context/overview.md
[http-headers]: https://api.dart.dev/dart-io/HttpHeaders-class.html
