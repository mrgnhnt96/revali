---
title: Middleware
description: Prepare a request before guards and the endpoint run - load data, set headers - or stop it early.
---

Middleware runs before [guards][guards] and the endpoint. Use it to prepare the request, for example by loading the current user into [`Data`][data-sharing] or setting a response header. It can also stop the request early. If the only job is to allow or deny access, write a [guard][guards] instead.

## Example

<CodeFile name="lib/components/tenant.dart">

```dart
import 'package:revali_router/revali_router.dart';

class Tenant implements LifecycleComponent {
  const Tenant();

  MiddlewareResult resolve(@Header('X-Tenant') String? tenant, Data data) {
    if (tenant == null) {
      return const MiddlewareResult.stop(body: 'X-Tenant header is required');
    }

    data.add(TenantId(tenant));

    return const MiddlewareResult.next();
  }
}

class TenantId {
  const TenantId(this.value);

  final String value;
}
```

</CodeFile>

<CodeFile name="routes/controllers/orders_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@Tenant()
@Controller('orders')
class OrdersController {
  const OrdersController();

  @Get()
  String list(@Data() TenantId tenant) => 'orders for ${tenant.value}';
}
```

</CodeFile>

```bash
curl -H 'X-Tenant: acme' http://localhost:8080/api/orders
# 200 {"data":"orders for acme"}

curl http://localhost:8080/api/orders
# 400 X-Tenant header is required
```

In debug mode the `400` body also has a `__DEBUG__` block appended.

## Results

| Result | Effect |
| --- | --- |
| `MiddlewareResult.next()` | Continue to the next middleware, then to the guards. |
| `MiddlewareResult.stop({statusCode, headers, body})` | End the request. The status defaults to `400`. |

The method can be `async` and return `Future<MiddlewareResult>`. `stop` takes the same arguments as the other error results. See [Error Responses][error-responses].

## Classic Style

As an alternative, implement `Middleware` and its `use` method, which receives the whole `Context`:

<CodeFile name="lib/components/tenant_middleware.dart">

```dart
import 'package:revali_router/revali_router.dart';

class TenantMiddleware implements Middleware {
  const TenantMiddleware();

  @override
  Future<MiddlewareResult> use(Context context) async {
    final tenant = context.request.headers.get('X-Tenant');
    if (tenant == null) {
      return const MiddlewareResult.stop();
    }

    context.data.add(TenantId(tenant));
    return const MiddlewareResult.next();
  }
}
```

</CodeFile>

Apply it with `@TenantMiddleware()`, or by type with `@Middlewares([TenantMiddleware])`.

[guards]: /constructs/revali_server/lifecycle-components/advanced/guards
[data-sharing]: /constructs/revali_server/context/data-sharing
[error-responses]: /constructs/revali_server/lifecycle-components#error-responses
