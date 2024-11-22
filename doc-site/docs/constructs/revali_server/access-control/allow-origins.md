# Allow Origins

## Explanation

### What Are Allow Origins?

Allow Origins are part of Cross-Origin Resource Sharing (CORS) and specify which origins (domains) are permitted to access a server's resources. The `Access-Control-Allow-Origin` header in the server's response determines whether a client from a different domain can make a request and receive a response. This is crucial in maintaining secure interactions between different web applications.

### Why Are Allow Origins Important?

Allow Origins are important for enforcing security in web applications. When a web page requests resources from a different domain, browsers enforce the same-origin policy to protect user data and prevent attacks, such as Cross-Site Request Forgery (CSRF). By using Allow Origins, servers explicitly list which external domains are trusted, enabling controlled resource sharing while minimizing security risks.

If the origin of the request is not allowed, the browser will block the request, ensuring that only authorized domains can access the resources.

### How Are Allow Origins Used?

The server sets the `Access-Control-Allow-Origin` header to control which domains can make cross-origin requests. For example:

```http
Access-Control-Allow-Origin: https://example.com
```

In this case, only `https://example.com` is allowed to access the server's resources. Alternatively, setting the value to `*` allows any domain to access the resource, which can be useful for public APIs but is typically avoided for sensitive data due to security concerns.

Properly configuring Allow Origins helps maintain a balance between accessibility and security, ensuring that only trusted clients are able to interact with server resources.

## Registering Allow Origins

To register Allow Origins in Revali, use the `@AllowOrigins` annotation. This annotation specifies the origins that are allowed to access the server's resources. If you don't specify any origins, the server will allow all origins by default.

Here's an example of how to register Allow Origins in Revali:

```dart
import 'package:revali_router/revali_router.dart';

@AllowOrigins({'https://example.com'})
@App()
class MyApp ...
```

:::tip
Similar to Lifecycle Components, `@AllowOrigins` can be scoped to apps, controllers, and requests. Learn about [scoping]
:::

:::caution
`@AllowOrigins` is all inclusive. If you specify any origins, only those origins will be allowed. If a request originates from a domain that is not specified in `@AllowOrigins`, the server will reject the request.
:::

### Wildcard Origins

Wildcard origins are used to allow any domain to access the server's resources. To enable wildcard origins, set the value to `*`:

```dart
@AllowOrigins.all() // or @AllowOrigins({'*'})
@App()
class MyApp ...
```

:::caution
Using wildcard origins can be useful for public APIs but should be used with caution due to security implications. Always consider the sensitivity of the data being shared and the potential risks associated with allowing unrestricted access.
:::

### Inheritance

By default, `@AllowOrigins` is inherited by child controllers and requests. This means that if you specify `@AllowOrigins` in an app, all controllers and requests within that app will inherit the allowed origins. Additionally, `@AllowOrigins` compound, meaning that if you specify `@AllowOrigins` for an app and a controller, the server will allow origins from both annotations.

```dart title="routes/my_app.dart"
// highlight-next-line
@AllowOrigins({'My-Origin'})
@App()
class MyApp ...
```

```dart title="routes/my_controller.dart"
// highlight-next-line
@AllowOrigins({'Another-Origin'})
@Controller('my-controller')
class MyController {

// highlight-next-line
    @AllowOrigins({'Yet-Another-Origin'})
    @Get('my-request')
    Future<Response> myRequest() {
        return Response.ok('Hello, World!');
    }
}
```

#### Allowed Origins

- App: `My-Origin`
- Controller: `My-Origin`, `Another-Origin`
- Request: `My-Origin`, `Another-Origin`, `Yet-Another-Origin`

### Disabling Inheritance

If you don’t want a child controller or request to inherit the allowed origins, you can disable inheritance by setting `inherit` to `false`.

```dart
@AllowOrigins({'My-Origin'}, inherit: false)
// or
@AllowOrigins.noInherit({'My-Origin'})
```

This configuration will only allow the specified origins in the controller or request, ignoring any origins specified in the parent app or controller.

## Preflight Requests

A preflight request is a CORS mechanism that checks if a client is allowed to make a request to a server. This request is sent before the actual request and includes the `OPTIONS` method. The server responds with the allowed headers, methods, and origins.

Revali automatically handles preflight requests.

### Failed CORs Requests

If a client sends a request with headers that are not allowed, the server will respond with a `403 Forbidden` status code with limited information.

:::tip
Learn how to configure the default response for [failed CORs requests][failed-cors-requests]
:::

### Success CORs Requests

If a client sends a request with allowed headers, the server will respond with a `200 OK` status code, along with the allowed headers.

[scoping]: ../lifecycle-components/overview.md#scoping
[failed-cors-requests]: ../../../revali/app-configuration/default-responses.md#failed-cors-origin
