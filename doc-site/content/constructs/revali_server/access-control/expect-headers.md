---
title: Expect Headers
description: Reject requests that are missing required headers with 403, before any lifecycle component runs.
---

`@ExpectHeaders` rejects a request with `403` unless it carries every listed header. The check runs with the other [access-control checks][lifecycle-order], before any middleware or guard. Use it for simple presence requirements such as a client id or an API version header. It only checks that the header is present. To validate a header's value, bind it with `@Header()` in a [guard][guards].

## Example

<CodeFile name="routes/controllers/reports_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Controller('reports')
class ReportsController {
  const ReportsController();

  @ExpectHeaders({'X-Client-Id', 'X-Api-Version'})
  @Get()
  String list() => 'reports';
}
```

</CodeFile>

| Request | Response |
| --- | --- |
| Both headers present | `200 {"data":"reports"}` |
| Either header missing | `403 CORS policy does not allow access with these headers.` |

Header names are matched case-insensitively. In debug mode the `403` body lists the missing headers. To change the body, see [Default Responses][default-responses].

The expected names are also sent back in `Access-Control-Allow-Headers`, so browsers are allowed to send them. See [CORS Response Headers][cors-headers].

## Scoping

`@ExpectHeaders` can go on the app, a controller, or an endpoint.

- Headers expected on the **app** are always required.
- Controller and endpoint annotations do **not** combine. The one closest to the endpoint wins: an endpoint's `@ExpectHeaders` replaces its controller's.

```dart
@ExpectHeaders({'X-Client-Id'})
@Controller('api')
class ApiController {
  const ApiController();

  @Get('a') // requires X-Client-Id
  String a() => 'a';

  @ExpectHeaders({'X-Api-Version'}) // requires only X-Api-Version
  @Get('b')
  String b() => 'b';
}
```

There is no `noInherit` variant, because the nearest annotation already replaces the ones above it.

Browser preflights (`OPTIONS` with `Access-Control-Request-Method`) are not checked, because a preflight only names the headers in `Access-Control-Request-Headers` without sending them. The real request that follows is checked. See [Preflight Requests][preflight].

[lifecycle-order]: /constructs/revali_server/lifecycle-components#lifecycle-order
[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[cors-headers]: /constructs/revali_server/access-control/allow-origins#cors-response-headers
[preflight]: /constructs/revali_server/access-control/allow-origins#preflight-requests
[default-responses]: /revali/app-configuration/default-responses
