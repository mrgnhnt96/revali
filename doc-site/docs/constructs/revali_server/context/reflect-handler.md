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

The `Reflector` class provides a way to analyze [`Meta`](./meta-handler.md) data on properties of a specific type.

:::tip
Learn how to create meta data using the [`Meta`](./meta.md) object
:::

### `get` (Reflector)

Getting a `Meta` instance for a specific property of a type.

```dart
ReadOnlyMetaHandler meta = context.reflect.get<T>().get('email');
```

### `meta`

Returns all the meta data of a specific type.

```dart
Map<String, ReadOnlyMeta> final meta = context.reflect.get<T>().meta;
```

:::tip
Learn more about [`Meta`](./meta.md)
:::
