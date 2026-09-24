---
title: Reflect
description: Read metadata annotations on the fields of your return types at runtime, for example to strip private fields from responses.
---

`Reflect` gives you the [metadata][meta] annotations on the **fields** of your own classes at runtime. Use it to build generic components that act on field annotations, such as removing fields marked private from every response.

Revali records a class for reflection when it is an endpoint's return type (or the output of a pipe) **and** at least one of its fields has an annotation that implements `MetaData`. Other classes return `null`.

## Example

Mark a field, then remove marked fields in a post interceptor:

<CodeFile name="lib/domain/user.dart">

```dart
import 'package:revali_router/revali_router.dart';

enum AccessType { public, private }

class Access implements MetaData {
  const Access(this.type);

  final AccessType type;
}

class User {
  const User({required this.name, required this.password});

  final String name;

  @Access(AccessType.private)
  final String password;

  Map<String, dynamic> toJson() => {'name': name, 'password': password};
}
```

</CodeFile>

<CodeFile name="lib/components/user_sanitizer.dart">

```dart
import 'package:revali_router/revali_router.dart';

class UserSanitizer implements LifecycleComponent {
  const UserSanitizer();

  InterceptorPostResult sanitize(Response response, Reflect reflect) {
    final reflector = reflect.get<User>();

    if (response.body.data case {'data': final Map<String, dynamic> data}) {
      final json = {...data};

      for (final key in data.keys) {
        final access = reflector?.get(key).get<Access>();

        if (access?.any((e) => e.type == AccessType.private) ?? false) {
          json.remove(key);
        }
      }

      response.body = {'data': json};
    }
  }
}
```

</CodeFile>

<CodeFile name="routes/controllers/users_controller.dart">

```dart
@Controller('users')
class UsersController {
  const UsersController();

  @UserSanitizer()
  @Get('me')
  User me() => const User(name: 'Ganondorf', password: 'i-hate-hyrule');
}
```

</CodeFile>

`GET /api/users/me` returns `{"data":{"name":"Ganondorf"}}`. The `password` field is removed.

## API

| Member | Returns | Behavior |
| --- | --- | --- |
| `reflect.get<T>()` | `Reflector?` | The reflector for class `T`, or `null` if `T` was not recorded |
| `reflector.get('field')` | `Meta` | The annotations on that field. Empty if it has none. |
| `reflector.meta` | `Map<String, Meta>` | Every annotated field, by name |
| `meta.get<A>()` | `List<A>?` | The `A` annotations on the field |

[meta]: /constructs/revali_server/context/meta
