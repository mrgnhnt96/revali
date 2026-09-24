---
title: Type Inference
description: How revali_swagger turns Dart parameter and return types into JSON Schema, and when to override it with @ApiType
---

`revali_swagger` reads the static types of handler parameters and return values and converts them to JSON Schema. This page lists the mapping, and what to do when a type cannot be mapped.

## Mapping

| Dart type | Schema |
| --- | --- |
| `String` | `{type: string}` |
| `int` | `{type: integer, format: int64}` |
| `double`, `num` | `{type: number, format: double}` |
| `bool` | `{type: boolean}` |
| `DateTime` | `{type: string, format: date-time}` |
| `Uri` | `{type: string, format: uri}` |
| `BigInt` | `{type: integer}` |
| `List<T>`, `Set<T>`, `Iterable<T>` | `{type: array, items: <T>}` |
| `Map<K, V>` | `{type: object, additionalProperties: <V>}`, or `additionalProperties: true` when `V` is `dynamic` |
| Record | `{type: object, properties: ...}`. Positional fields are named `field0`, `field1`, ... |
| Enum | `$ref` to `{type: string, enum: [<value names>]}` |
| Custom class | `$ref` to an object schema built from its fields |
| Sealed class | `$ref` to `{oneOf: [$ref to each direct subtype]}` |
| `dynamic` | `{}` (any value) |
| `void`, `Future<void>` | no response body |
| `T?` | `T`'s schema plus `nullable: true` (wrapped in `allOf` for `$ref`s) |

`Future<T>` and `Stream<T>` are unwrapped to `T`.

Enums, custom classes and sealed classes are registered once under `components/schemas` and referenced with `$ref`. Schemas that nothing references are removed.

## Custom classes

The schema includes every non-static field of the class and its superclasses (stopping at SDK classes). Non-nullable fields are listed in `required`. Getters and constructor parameters are not considered, and the schema describes field names, not a custom `toJson` output.

```dart
class CreateUserBody {
  const CreateUserBody({required this.name, this.bio});

  final String name;
  final String? bio;
}
```

```yaml
CreateUserBody:
  type: object
  properties:
    name:
      type: string
    bio:
      type: string
      nullable: true
  required:
    - name
```

## Sealed classes

Each direct subtype declared in the same library becomes its own schema, and the sealed class becomes a `oneOf` over them:

```dart
sealed class Shape {}

class Circle extends Shape {
  Circle(this.radius);
  final double radius;
}

class Rect extends Shape {
  Rect(this.width, this.height);
  final double width;
  final double height;
}
```

```yaml
Shape:
  oneOf:
    - $ref: '#/components/schemas/Circle'
    - $ref: '#/components/schemas/Rect'
```

## When @ApiType is needed

When a type has no reliable mapping, the generator picks a fallback and prints a warning to stderr:

| Type | Fallback | Warning starts with |
| --- | --- | --- |
| `Duration` | `{type: string}` | `Type 'Duration' has no standard JSON serialization format.` |
| Other SDK types (e.g. `RegExp`) | `{}` | `Unknown SDK type '...'` |
| Types with nothing to introspect | `{type: object}` | `Type '...' has no introspectable element.` |

Each line is prefixed with `[revali_swagger] WARNING:`. Also reach for `@ApiType` when a class serializes to something other than its fields, such as a value object sent as a plain string.

Annotate the parameter or field with the schema it actually has on the wire:

```dart
Future<void> schedule(
  @Query() @ApiType('integer', format: 'int64') Duration delay,
) async => ...;
```

See [@ApiType](/constructs/revali_swagger/annotations#apitype).
