---
title: Type Inference
sidebar_position: 3
description: How Dart types are converted to JSON Schema in the generated spec
---

# Type Inference

Revali Swagger reads the static types of your parameters and return values at code-generation time and converts them to JSON Schema automatically. No annotations are required for supported types.

## Supported Types

| Dart Type                 | OpenAPI Schema                                     |
| ------------------------- | -------------------------------------------------- |
| `String`                  | `{type: string}`                                   |
| `int`                     | `{type: integer, format: int64}`                   |
| `double`                  | `{type: number, format: double}`                   |
| `num`                     | `{type: number}`                                   |
| `bool`                    | `{type: boolean}`                                  |
| `DateTime`                | `{type: string, format: date-time}`                |
| `Uri`                     | `{type: string, format: uri}`                      |
| `List<T>` / `Iterable<T>` | `{type: array, items: <T schema>}`                 |
| `Set<T>`                  | `{type: array, items: <T schema>}`                 |
| `Map<K, V>`               | `{type: object, additionalProperties: <V schema>}` |
| Named record              | `{type: object, properties: {...}}`                |
| Enum                      | `{type: string, enum: [values...]}`                |
| Sealed class              | `{oneOf: [$ref to each subtype]}`                  |
| Custom class              | `{$ref: '#/components/schemas/ClassName'}`         |
| `T?` (nullable)           | schema + `nullable: true`                          |
| `void` / `Future<void>`   | — (no response body emitted)                       |

### Custom Classes

For custom classes, all non-static fields are included as properties. The construct walks up the superclass chain so inherited fields are included as well. Fields annotated with `@ApiHidden` or `apiHidden` are excluded.

Required fields (non-nullable, no default value) are listed in the `required` array.

```dart
class CreateUserBody {
  final String name;
  final String email;
  final String? bio;  // nullable → not required

  const CreateUserBody({
    required this.name,
    required this.email,
    this.bio,
  });
}
```

Produces:

```yaml
CreateUserBody:
  type: object
  properties:
    name:
      type: string
    email:
      type: string
    bio:
      type: string
      nullable: true
  required:
    - name
    - email
```

### Sealed Classes

Each concrete subtype becomes its own schema in `components/schemas`. The sealed class itself becomes a `oneOf` reference list:

```dart
sealed class Shape {}
class Circle extends Shape { final double radius; }
class Rect extends Shape { final double width; final double height; }
```

Produces:

```yaml
Shape:
  oneOf:
    - $ref: '#/components/schemas/Circle'
    - $ref: '#/components/schemas/Rect'
Circle:
  type: object
  properties:
    radius:
      type: number
      format: double
  required:
    - radius
Rect:
  type: object
  ...
```

### Enums

Enum values are emitted as a string `enum` by default using the `.name` of each value:

```dart
enum Status { active, inactive, suspended }
```

Produces:

```yaml
Status:
  type: string
  enum:
    - active
    - inactive
    - suspended
```

---

## When @ApiType is Needed

Some Dart types cannot be resolved to a JSON Schema automatically. When this happens, a warning is printed to stderr during generation:

```txt
[revali_swagger] Warning: cannot infer schema for type 'Duration'.
Use @ApiType to specify the schema explicitly.
```

Common cases where `@ApiType` is required:

- **`Duration`** — no standard JSON representation
- **`Object` / `dynamic`** — too broad to infer
- **External types** you don't control (e.g. from third-party packages)
- **Types with custom serialization** where the wire format differs from the class fields

Fix the warning by annotating the parameter or field with `@ApiType`:

```dart
// Before — generates a warning and emits {} for the schema.
Future<void> schedule(@Query() Duration delay) async { ... }

// After — emits {type: integer, format: int64}.
Future<void> schedule(
  @Query()
  @ApiType(type: 'integer', format: 'int64')
  Duration delay,
) async { ... }
```

See the [Annotations](./annotations#apitype) page for a full list of common `@ApiType` use cases.

---

## Schema Deduplication

Complex types (custom classes, sealed classes, enums) are registered in `components/schemas` and referenced by `$ref` throughout the spec. If the same type appears in multiple routes, it is only defined once.

Schemas that are never referenced from any path (after all routes are processed) are automatically pruned from `components/schemas` to keep the spec clean.
