---
title: Overview
description: The object that represents the incoming HTTP request
---

The `Request` is the object that represents the incoming HTTP request. It contains all the information about the request, such as the headers, the body, the URL, and the method. While the [response] can be heavily modified, the request is read-only, with the exception of the headers.

## Read-Only

The request is read-only, meaning that you cannot modify the request body, URL, method, or any other property of the request. This is because the request is already sent by the client, and the server should respond to the request as it is.

<Callout type="important">

Only the headers can be modified in the request

</Callout>

## Accessing the Request

### Via Context

The `Request` object can be accessed through the `request` property in the context of the Lifecycle Components.

```dart
final request = context.request;
```

<Callout type="tip">

Read more about the [Lifecycle Component's context][lifecycle-context].

</Callout>

### Via Binding

The `Request` object can be accessed via the controller's endpoint by adding the `ReadOnlyRequest` parameter to the endpoint method.

```dart
@Get()
Future<void> helloWorld(
    ReadOnlyRequest request,
) async {
    ...
}
```

<Callout type="warning">

Using the `ReadOnlyRequest` parameter in the endpoint method is not recommended. Use the `context` from Lifecycle Components to access the request.

By avoiding the `ReadOnlyRequest` parameter, you can keep your endpoint methods clean, focused, and testable.

</Callout>

## Client IP

Every request exposes the client IP as `request.ip`. Use [`@Ip()`](/constructs/revali_server/core/binding#ip---client-ip) in endpoints or read `request.ip` from context.

By default this is the TCP remote address. When the app runs behind a trusted reverse proxy, configure [`trustedProxy`](/revali/app-configuration/create-an-app#trusted-proxy) on your app so Revali resolves the IP from proxy headers (for example `X-Forwarded-For`).

See [Client IP](/constructs/revali_server/request/client-ip) for binding examples, `TrustedProxy` options, and security notes.

[response]: /constructs/revali_server/response
[lifecycle-context]: /constructs/revali_server/context
