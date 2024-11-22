---
description: A preflight request that return the possible methods
---

# Option Requests

## Explanation

### What Are OPTIONS Requests?

An OPTIONS request is an HTTP method used to describe the communication options available for a specific resource or server. When a client makes an OPTIONS request, the server responds with the supported HTTP methods (e.g., GET, POST, PUT) and other information about the resource. This allows the client to understand what actions it can take before making an actual request.

### Why Are OPTIONS Requests Important?

In the context of CORS, browsers automatically send OPTIONS requests—called preflight requests—to determine if the actual request is safe to send. This ensures the server explicitly permits the intended action, preventing unauthorized cross-origin operations.

### How Are OPTIONS Requests Used?

An OPTIONS request is made by setting the HTTP method to `OPTIONS`. For example:

```http
OPTIONS /example HTTP/1.1
Host: www.example.com
```

The server then responds with headers that describe the supported methods and other relevant information:

```http
HTTP/1.1 200 OK
Access-Control-Allow-Methods: GET, POST, OPTIONS
```

This response informs the client of what it can and cannot do with the resource, making OPTIONS requests useful for preflight checks, understanding server capabilities, and ensuring compliance with CORS policies.

## Usage

Revali Server automatically handles OPTIONS requests for you.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('users')
class MyController {
    @Get()
    void user() {}

    @Post()
    void save() {}
}
```

In the example above, when a client sends an OPTIONS request to `/users`, Revali Server automatically responds with a `200 OK`, along with the allowed methods for the resource.

```http
Access-Control-Allow-Methods: GET, POST, OPTIONS
```
