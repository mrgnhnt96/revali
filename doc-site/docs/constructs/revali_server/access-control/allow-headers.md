# Allow Headers

## Explanation

### What Are Allow Headers?

Allow Headers are a mechanism used in HTTP requests to indicate which headers a client is allowed to use when making a request to a server. Specifically, these headers are part of Cross-Origin Resource Sharing (CORS), a protocol that ensures secure resource sharing across different domains. By defining which headers are permitted, the server can control how clients interact with its resources.

### Why Are Allow Headers Important?

Allow Headers are for web application security. When a client sends a request—especially across domains—the server decides whether to accept it and which information is allowed. Specifying allowed headers limits received information, reducing risks of sensitive data exposure or attacks.

Without Allow Headers, unauthorized data could be included in requests, leading to vulnerabilities or performance issues. Allow Headers create predictable and secure client-server interactions.

### How Are Allow Headers Used?

Allow Headers are configured in the server response, usually through the `Access-Control-Allow-Headers` header. This header lists all the request headers that are allowed during the preflight or actual request. Here’s a typical usage example:

```http
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
```

In the above example, the server allows clients to use the `Content-Type`, `Authorization`, and `X-Requested-With` headers in their requests. This configuration helps developers fine-tune their API security by explicitly specifying which headers are trusted.

## Registering Allow Headers

To register Allow Headers in Revali, use the `@AllowHeaders` annotation. This annotation specifies the headers that the server allows in requests. If you don’t specify any headers, the server will allow all headers by default.

Here’s an example of how to register Allow Headers in Revali:

```dart
import 'package:revali_router/revali_router.dart';

@AllowHeaders({'Content-Type', 'Authorization', 'X-Requested-With'})
@App()
class MyApp ...
```

:::tip
Similar to Lifecycle Components, `@AllowHeaders` can be scoped to apps, controllers, and requests. Learn about [scoping](../lifecycle-components/overview#scoping)
:::

:::caution
`@AllowHeaders` is all inclusive. If you specify any headers, only those headers will be allowed. Meaning that if a request contains a header that is not specified in `@AllowHeaders`, the server will reject the request.
:::

### Simple Headers

Simple headers are headers that are safe to include in a request without a preflight request. These headers include:

- `Accept`
- `Accept-Language`
- `Content-Language`
- `Content-Type`
- `Range`

These headers are automatically allowed by the server, so you don’t need to specify them in `@AllowHeaders`.

### Inheritance

By default, `@AllowHeaders` is inherited by child controllers and requests. This means that if you specify `@AllowHeaders` in an app, all controllers and requests within that app will inherit the allowed headers. Additionally, `@AllowHeaders` compound, meaning that if you specify `@AllowHeaders` for an app and a controller, the server will allow headers from both annotations.

```dart title="routes/my_app.dart"
// highlight-next-line
@AllowHeaders({'My-Header'})
@App()
class MyApp ...
```

```dart title="routes/my_controller.dart"
// highlight-next-line
@AllowHeaders({'Another-Header'})
@Controller('my-controller')
class MyController {

// highlight-next-line
    @AllowHeaders({'Yet-Another-Header'})
    @Get('my-request')
    Future<Response> myRequest() {
        return Response.ok('Hello, World!');
    }
}
```

#### Allowed Headers

- App: `My-Header`
- Controller: `My-Header`, `Another-Header`
- Request: `My-Header`, `Another-Header`, `Yet-Another-Header`

### Disabling Inheritance

If you don’t want a child controller or request to inherit the allowed headers, you can disable inheritance by setting `inherit` to `false`.

```dart
@AllowHeaders({'My-Header'}, inherit: false)
// or
@AllowHeaders.noInherit({'My-Header'})
```

This configuration will only allow the specified headers in the controller or request, ignoring any headers specified in the parent app or controller.

## Preflight Requests

A preflight request is a CORS mechanism that checks if a client is allowed to make a request to a server. This request is sent before the actual request and includes the `OPTIONS` method. The server responds with the allowed headers, methods, and origins.

Revali automatically handles preflight requests.

### Failed CORs Requests

If a client sends a request with headers that are not allowed, the server will respond with a `403 Forbidden` status code with limited information.

:::tip
Learn how to configure the default response for [failed CORs requests](../../../revali/app-configuration/default-responses#failed-cors)
:::

### Success CORs Requests

If a client sends a request with allowed headers, the server will respond with a `200 OK` status code, along with the allowed headers.
