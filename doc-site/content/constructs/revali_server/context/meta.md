---
title: Meta
description: Attach your own annotations to endpoints and controllers and read them in lifecycle components.
---

Metadata lets you label endpoints and controllers with your own annotations and read those labels while a request runs. A common use is marking endpoints `@Public()` so an auth guard can skip them, or tagging an endpoint with the role it requires. Revali collects any annotation whose class implements `MetaData`.

## Example

<CodeFile name="lib/meta/public.dart">

```dart
import 'package:revali_router/revali_router.dart';

class Public implements MetaData {
  const Public();
}
```

</CodeFile>

<CodeFile name="lib/components/auth_guard.dart">

```dart
import 'package:revali_router/revali_router.dart';

class AuthGuard implements LifecycleComponent {
  const AuthGuard();

  GuardResult check(MetaScope meta, @Header('Authorization') String? token) {
    if (meta.has<Public>()) {
      return const GuardResult.pass();
    }

    return token == null
        ? const GuardResult.block(statusCode: 401)
        : const GuardResult.pass();
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/status_controller.dart">

```dart
import 'package:revali_router/revali_router.dart';

@AuthGuard()
@Controller('status')
class StatusController {
  const StatusController();

  @Public()
  @Get('health')
  String health() => 'ok';

  @Get('details')
  String details() => 'secret details';
}
```

</CodeFile>

`GET /api/status/health` returns `200` without a token. `GET /api/status/details` returns `401` without one.

## Reading Metadata

Bind `MetaScope` (or `Meta`) as a parameter in a component or endpoint.

| Member | Returns | Behavior |
| --- | --- | --- |
| `get<T>()` | `List<T>?` | Every `T` annotation on the endpoint. If the endpoint has none, the `T` annotations on its controller. `null` if neither has any. |
| `has<T>()` | `bool` | Whether the endpoint or its controller has a `T` annotation |
| `direct` | `Meta` | Only the annotations on the endpoint |
| `inherited` | `Meta` | Only the annotations on the controller |
| `add<T>(T value)` | `void` | Adds a value at runtime. Later components and the endpoint see it. |

Metadata on the `@App()` class is visible too. It is stored with the endpoint's own annotations, in `direct`.

`get` returns a list because the same annotation can appear more than once. For an annotation you expect once, use `meta.get<CodeName>()?.single`:

```dart
class CodeName implements MetaData {
  const CodeName(this.name);

  final String name;
}

@CodeName('API-1234')
@Get('data')
String data(MetaScope meta) => meta.get<CodeName>()?.single.name ?? 'none';
// GET /api/.../data -> {"data":"API-1234"}
```

A metadata class needs a `const` constructor, because it is used as an annotation. Metadata on a class's fields is read with [Reflect][reflect] instead.

[reflect]: /constructs/revali_server/context/reflect
