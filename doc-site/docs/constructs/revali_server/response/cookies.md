---
title: Cookies
description: Cookies are pieces of data that are stored on the client side and sent to the server with each request.
---

# Cookies

Cookies are pieces of data that are stored on the client side and sent to the server with each request. They are used to store information about the user and their interactions with the server. Cookies can be used to store user preferences, track user activity, and maintain user sessions, among other things.

## Setting Cookies

Cookies can be set by the server and sent to the client in the response. The client will then store the cookies and send them back to the server with each subsequent request.

## Accessing Cookies

### Via Context

The cookies sent by the client can be accessed through the `request` property in the context of the Lifecycle Components.

```dart
final cookies = context.request.headers.cookies;
final cookieValue = cookies['cookieName'];
```

To tell the client which cookies to be set, you'll use the `Set-Cookie` header, which can be accessed in the response's headers.

To set cookies in the response, you can use the `response.headers` property in the context of the Lifecycle Components.

```dart
context.response.headers.setCookies['cookieName'] = 'cookieValue';
```

:::tip
Read more about the [Lifecycle Component's context][lifecycle-context].
:::

### Via Binding

The cookies sent by the client (in the request) can be accessed via the lifecycle method or controller's endpoint by adding the `ReadOnlyCookies` type to a parameter.

```dart
@Get()
Future<void> helloWorld(
    ReadOnlyCookies cookies,
) async {
    final cookieValue = cookies['cookieName'];
}
```

To set cookies in the response, you can use the `MutableSetCookies` type in the lifecycle method or controller's endpoint.

```dart
Future<MiddlewareResult> setupAuth(
    ReadOnlyCookies cookies,
    MutableSetCookies setCookies,
) async {
    final token = cookies['token'];

    if (token == null) {
        return MiddlewareResult.stop(
            statusCode: 401,
            body: 'Unauthorized',
        );
    }

    final newToken = await refreshToken(token)

    setCookies['token'] = newToken;
    setCookies.expires = DateTime.now().add(Duration(days: 1));
}
```

:::tip
Read more about the [Lifecycle Components][lifecycle-components].
:::

[lifecycle-context]: ../context/overview.md
[lifecycle-components]: ../lifecycle-components/overview.md
