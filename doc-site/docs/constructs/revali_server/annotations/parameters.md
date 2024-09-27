---
title: Parameters
---

# Parameter Annotations

Parameter annotations are used to bind parameters to values from the request. They can be used to bind path parameters, query parameters, headers, request bodies, and more.

| Annotation | Description |
| --- | --- |
| `@Param()` | Binds a path parameter ([docs](#param)) |
| `@Query()` | Binds a query parameter ([docs](#query)) |
| `@Header()` | Binds a header ([docs](#header)) |
| `@Body()` | Binds the request body ([docs](#body)) |
| `@Dep()` | Binds a dependency ([docs](#dep)) |
| `CustomParam` | Allows you to create custom parameter annotations ([docs](#customparam)) |

:::important
You can only use one parameter annotation per method parameter.
:::

## `@Param()`

The `Param` annotation is used to bind a path parameter to a method parameter.

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
Path parameters are always returned as a `String`. If you need to convert the value to another type, you can use a [pipe](#param-1).
:::

:::tip
Check out the [Pipe][pipes] documentation on how to create pipes.
:::

## `@Query()`

The `Query` annotation is used to bind a query parameter to a method parameter.

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
Query parameters are always returned as `String`s. If you need to convert the value to another type, you can use a [pipe](#query-1).
:::

:::tip
Check out the [Pipe][pipes] documentation on how to create pipes.
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

The `Header` annotation is used to bind a header to a method parameter.

```dart showLineNumbers
@Get()
String getUser(
  // highlight-next-line
  @Header(HttpHeaders.acceptHeader) String contentType,
) {
  return 'Content Type: $contentType';
}
```

### All Values

Headers can have multiple values. If you're expecting multiple values, you can use the `@Header.all()` annotation.

```dart
@Get()
String getUser(
  // highlight-next-line
  @Header.all() List<String> ids,
) {
  return 'User IDs: $ids';
}
```

:::warning
If you don't use the `@Header.all()` annotation and there are multiple values, the values will be joined using commas (`,`).
:::

## `@Body()`

:::important 🚧 Under Construction 🚧
:::

## `@Dep()`

:::important 🚧 Under Construction 🚧
:::

## `CustomParam`

:::important 🚧 Under Construction 🚧
:::

## Binding

By default, `revali_router` will use the name of the method's parameter to bind a value from the request. This works well when the names match, however, there will be times where the names don't match and will need to be bound manually.

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

Below the path parameter is named `:firstName` (line 1) and the method parameter is named `name` (line 3). Without binding the parameter, the `@Param` annotation would try to bind a `:firstName` path parameter which doesn't exist. This would result in a compile-time error.

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
In the examples above, we used the `@Param` annotation, but the principles apply to all parameter annotations.
:::

## Pipe Transform

In most cases, the value you bind from the request will need to be transformed or converted before using it. This can be done by passing a `Pipe` to the annotation.

:::tip
Check out the [Pipe][pipes] documentation on how to create pipes.
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

[pipes]: ./pipes.md
