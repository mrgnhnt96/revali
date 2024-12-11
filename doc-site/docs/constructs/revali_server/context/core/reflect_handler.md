---
description: Read metadata associated with Types
---

# Reflect Handler

> Implements: `ReadOnlyReflectHandler`

The `ReflectHandler` is a helper class that provides a way to analyze meta data of a specific type.

## Properties

### `get`

Gets a `Reflector` instance for a specific type. The specific type is typically a class that you've defined.

```dart
Reflector reflector = context.reflect.get<T>();
```

### `byType`

An alternative way to retrieve the you can use the `byType` method.

## Reflector

The `Reflector` class provides a way to analyze [`Meta`][meta-handler] data on properties of a specific type.

:::tip
Learn how to create meta data using the [`Meta`][meta] object
:::

### `get`

Getting a `Meta` instance for a specific property of a type.

```dart
ReadOnlyMetaHandler meta = context.reflect.get<T>().get('email');
```

```dart
Reflector reflector = context.reflect.byType(User);
```

### `meta`

Returns all the meta data of a specific type.

```dart
Map<String, ReadOnlyMeta> final meta = context.reflect.get<T>().meta;
```

:::tip
Learn more about [`Meta`][meta]
:::

[meta-handler]: ./meta_handler.md
[meta]: ../../context/core/meta.md
