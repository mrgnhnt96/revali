---
description: Require specific headers in a request
---

# Expect Headers

Similar to [Allow Headers][allow-headers], you can specify which headers the server expects in a request. The server will reject any request that does not contain the expected headers. The server will **not** reject a request if the request contains additional headers that are not specified in `@ExpectHeaders`.

## Registering Expect Headers

To register Expect Headers in Revali, use the `@ExpectHeaders` annotation.

Here’s an example of how to register Expect Headers in Revali:

```dart
import 'package:revali_router/revali_router.dart';

@ExpectHeaders({'X-My-Header'})
@App()
class MyApp ...
```

:::tip
Similar to Lifecycle Components, `@ExpectHeaders` can be scoped to apps, controllers, and requests. Learn about [scoping].
:::

## Preflight Requests

A preflight request is a CORS mechanism that checks if a client is allowed to make a request to a server. This request is sent before the actual request and includes the `OPTIONS` method. The server responds with the allowed headers, methods, and origins.

Revali automatically handles preflight requests.

### Failed Preflight Requests

If a preflight request fails, the server will respond with a `403 Forbidden` status code with limited information.

:::tip
Learn how to configure the default response for [failed CORS requests][failed-cors-requests].
:::

### Successful Preflight Requests

If a preflight request is successful, the server will respond with the allowed headers, methods, and origins.

[allow-headers]: ./allow-headers.md
[scoping]: ../lifecycle-components/overview.md#scoping
[failed-cors-requests]: ../../../revali/app-configuration/default-responses.md#failed-cors-origin
