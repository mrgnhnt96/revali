---
title: Binding
sidebar_position: 2
---

# Binding Annotations

Binding annotations are a set of annotations tailored to extract the provided arguments from their corresponding locations.

| Annotation  | Description                         | Requests | Controllers |
| ----------- | ----------------------------------- | :------: | :---------: |
| `@Param()`  | Binds a path parameter              |    ✅    |     ❌      |
| `@Query()`  | Binds a query parameter             |    ✅    |     ❌      |
| `@Header()` | Binds a header                      |    ✅    |     ❌      |
| `@Body()`   | Binds the body                      |    ✅    |     ❌      |
| `@Dep()`    | Binds a dependency                  |    ✅    |     ✅      |
| `@Data()`   | Binds a value from the Data Handler |    ✅    |     ✅      |
| `Bind`      | Binds a custom value                |    ✅    |     ✅      |

:::important
You can only use one parameter annotation per parameter.
:::

:::info
There are [some classes][implied-binding] that can be implied by the parameter's type and do not require binding annotations
:::

## `@Param()`

The `Param` annotation is used to bind a path parameter from a request to a method parameter.

In the example below, the `name` parameter is bound to the `:name` path parameter.

```dart showLineNumbers title="say_hello"
@Get(':name')
String sayHello(
  @Param() String name,
) {
  return 'Hello, $name!';
}
```

You are not limited to a single path parameter. You can define as many as you need.

```dart
import 'package:revali_router/revali_router.dart';

@Controller('shop/:shopId')
class ShopController {
  const ShopController();

  @Get(':productId')
  String getProduct(
    @Param() String shopId,
    @Param() String productId,
  ) {
    return 'Shop ID: $shopId, Product ID: $productId';
  }
}
```

:::caution
Path parameters are always returned as a `String`. If you need to convert the value to another type, you can use a [param-pipe].
:::

## `@Query()`

The `Query` annotation is used to bind a query parameter from a request to a method parameter.

In the example below, the `id` method parameter (line 3) is bound to the `id` query parameter (not shown).

```dart showLineNumbers
@Get()
String getUser(
  // highlight-next-line
  @Query() String id,
) {
  return 'User ID: $id';
}
```

If the query parameter is optional, the method parameter should be nullable.

```dart
@Get()
String getUser(
  // highlight-next-line
  @Query() String? id, // The query parameter may not exist
) {
  return 'User ID: $id';
}
```

:::caution
Query parameters are always returned as `String`s. If you need to convert the value to another type, you can use a [param-pipe][query-pipe].
:::

### All Values

Query parameters can have multiple values. If you're expecting multiple values, you can use the `@Query.all()` annotation.

```dart
@Get()
String getUser(
  // highlight-next-line
  @Query.all() List<String> ids,
) {
  return 'User IDs: $ids';
}
```

::::info Example
If the query parameter is `?ids=1&ids=2`, the response will be `User IDs: [1, 2]`.

:::warning
If you don't use the `@Query.all()` annotation, only the last value will be bound. `?ids=1&ids=2` will result in `User IDs: 2`.
:::
::::

## `@Header()`

The `Header` annotation is used to bind a header entry from a request to a method parameter.

```dart showLineNumbers
@Get()
String getUser(
  // highlight-next-line
  @Header(HttpHeaders.acceptHeader) String accept,
) {
  return 'Content Type: $accept';
}
```

:::caution
Header values are always returned as `String`s. If you need to convert the value to another type, you can use a [pipe][header-pipe].
:::

### All Values

Headers can have multiple values. If you're expecting multiple values, you can use the `@Header.all()` annotation.

```dart
@Get()
String getUser(
  // highlight-next-line
  @Header.all(HttpHeaders.acceptHeader) List<String> accept,
) {
  return "User IDs: ${accept.join(', ')}";
}
```

:::warning
If you don't use the `@Header.all()` annotation and there are multiple values, the values will be joined using commas (`,`).
:::

## `@Body()`

The `Body` annotation is used to bind the request body, or part of it, to a method parameter.

```dart showLineNumbers
@Post()
String createUser(
  // highlight-next-line
  @Body() Map<String, dynamic> body,
) {
  return 'User: $user';
}
```

::::note
The `@Body` type can be used with any [built-in][built-in-types] type, not just `Map<String, dynamic>`, it should be whatever you expect the body to be.

If you need to convert the value to another type, you can use a [pipe][body-pipe].
::::

### Specific Values

If you only need a specific value from the body, you can pass a list of keys to the `@Body` annotation.

```dart
@Post()
String createUser(
  // highlight-next-line
  @Body(['data', 'email']) String email,
) {
  return 'Email: $email';
}
```

If the request body is:

```json
{
    "data": {
        "email": "revali@email.com",
        "password": "123456"
    }
}
```

The value that will be bound will be `revali@email.com` and the `password` value will be ignored.

:::warning
If the body doesn't contain the specified keys, the method will throw a runtime error. Unless the type is nullable, in which case it will be `null`.
:::

## `@Dep()`

The `Dep` annotation is used to bind a dependency from the [DI object][di-object] to a parameter.

:::tip
Learn how to [configure dependencies][configure-dependencies].
:::

While you can bind a dependency to a parameter in a request, it is recommended to use the parameters of the controller's constructor instead.

```dart showLineNumbers
@Controller()
class UserController {
  const UserController(
    // highlight-next-line
    @Dep() this._userService,
  );

  final UserService _userService;

  @Get()
  String getUser() {
    return 'User: ${_userService.getUser()}';
  }
}
```

:::warning
If the dependency doesn't exist, the method will throw a runtime error. Controllers are resolved as soon as the application starts, so any missing dependencies will be caught early.
:::

## `@Data()`

The `Data` annotation is used to bind a value from the [Data Handler][data-handler] to a parameter.

```dart showLineNumbers
@Get()
String getUser(
  // highlight-next-line
  @Data() User user,
) {
  return 'User: $user';
}
```

::::warning
If the value doesn't exist within the Data Handler, the method will throw a runtime error.

:::tip
If the value is optional, you can make the parameter nullable. This will prevent the method from throwing an error if the value doesn't exist.

```dart
@Data() User? user,
```

:::
::::

## `Bind`

Occasionally, you may need a custom parameter annotation. Whether you need access to the entire request object or you need to bind a value in a specific way, you can create a custom parameter annotation.

### Create

To create a custom parameter annotation, you need to implement the class `Bind` and override the `bind` method.

```dart title="lib/custom_params/bind_user.dart"
import 'package:revali_router/revali_router.dart';

class GetUser extends Bind<User> {
  const GetUser();

  @override
  User bind(BindContext context) {
    ...
  }
}
```

:::important
In order to use the `GetUser` class as an annotation, you need to ensure that the constructor is `const`.
:::

### Use

#### Via Annotation

To use the `GetUser` class, annotate the method parameter with it.

```dart showLineNumbers
@Get()
String getUser(
  // highlight-next-line
  @GetUser() User user,
) {
  return 'User: $user';
}
```

#### Via `Binds`

If you have an argument within your custom parameter that you can't provide at compile-time, you can use the `Binds` annotation and use the `GetUser` class as a type reference.

```dart showLineNumbers
@Get()
String getUser(
  // highlight-next-line
  @Binds(GetUser) User user,
) {
  return 'User: $user';
}
```

:::tip
Read more about why `GetUser` is being used as a [Type Reference][using-types-in-references]
:::

## Name References

By default, `revali_router` will use the name of the method's parameter as the key to retrieve the respective value from the request. This works well when the name of the parameter and the key of the data you're attempting to bind match, however, there will be times where the names don't match and will need to be bound manually.

In the example below, the `firstName` method parameter (line 3) is bound to the `firstName` path parameter (line 1). This means that the path parameter will be properly bound to the method parameter.

```dart showLineNumbers
@Get(':firstName')
String sayHello(
  // highlight-next-line
  @Param() String firstName,
) {
  return 'Hello, $firstName!';
}
```

:::info Example
If the request path is `/john`, the response will be `Hello, john!`.
:::

Below the path parameter is named `:firstName` (line 1) and the method parameter is named `name` (line 3). What happens here is the `@Param` annotation would try to bind a `:name` path parameter which doesn't exist. This would result in a compile-time error.

```dart showLineNumbers
@Get(':firstName')
String sayHello(
  // highlight-next-line
  @Param() String name,
) {
  return 'Hello, $name!';
}
```

To remedy this, you will need to pass the name of the path parameter (`:firstName`) to the `@Param` annotation.

```dart showLineNumbers
@Get(':firstName')
String sayHello(
  // highlight-next-line
  @Param('firstName') String name,
) {
  return 'Hello, $name!';
}
```

:::warning
Names are case sensitive. `user-id` is not the same as `userId`.
:::

:::note
In the examples above, we used the `@Param` annotation, but the principles apply to all binding annotations.
:::

## Pipe Transform

In most cases, the value you bind from the request will need to be transformed or converted before using it. This can be done by passing a `Pipe` to the annotation.

:::tip
Check out the [Pipe][pipes] documentation on how to create pipes.
:::

:::tip
Read more about why the pipe being used as a [Type Reference][using-types-in-references] is important
:::

### Param

```dart
@Param(':user', GetUserPipe) User user,
@Param.pipe(GetUserPipe) User user,
```

### Query

```dart
@Query(':user', GetUserPipe) User user,
@Query.all(':user', GetUserPipe) User user,
@Query.pipe(GetUserPipe) User user,
@Query.allPipe(GetUserPipe) User user,
```

### Header

```dart
@Header(':user', GetUserPipe) User user,
@Header.pipe(GetUserPipe) User user,
```

### Body

```dart
@Body(['data'], GetUserPipe) User user,
@Body.pipe(GetUserPipe) User user,
```

[pipes]: ../core/pipes.md
[built-in-types]: https://dart.dev/language/built-in-types
[implied-binding]: ./implied_binding.md
[di-object]: ../../../revali/app-configuration/configure-dependencies.md#the-di-object
[configure-dependencies]: ../../../revali/app-configuration/configure-dependencies.md#registering-dependencies
[data-handler]: ../../../constructs/revali_server/context/core/data_handler.md
[using-types-in-references]: ../../../constructs/revali_server/tidbits.md#using-types-in-annotations

[param-pipe]: #param-1
[query-pipe]: #query-1
[body-pipe]: #body-1
[header-pipe]: #header-1
