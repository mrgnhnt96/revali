---
title: Annotations
sidebar_position: 2
description: Optional annotations for enriching the generated OpenAPI spec
---

# Annotations

All annotations are provided by the `revali_swagger_annotations` package. They are optional — the construct produces a valid spec without any of them.

## Summary

| Annotation                 | Target               | Purpose                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `@ApiInfo`                 | App class            | Override title, version, and description |
| `@ApiTag`                  | Controller or method | Group endpoints in the spec              |
| `@ApiSummary`              | Method               | Short one-line summary                   |
| `@ApiDescription`          | Method               | Multi-line description                   |
| `@ApiResponse`             | Method               | Document additional response codes       |
| `@ApiHidden` / `apiHidden` | Controller or method | Exclude from the spec entirely           |
| `@ApiType`                 | Parameter or field   | Override the inferred JSON Schema type   |

---

## @ApiInfo

Overrides the top-level `info` block in the generated spec. Place it on your Revali app class.

```dart
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

@ApiInfo(
  title: 'Payments API',
  version: '3.0.0',
  description: 'Handles all payment processing operations.',
)
@App(host: 'localhost', port: 8080)
void main() async { ... }
```

The same values can also be set in `revali.yaml`. See [Configuration](./getting-started/configuration) for details.

---

## @ApiTag

By default, each controller contributes its class name (snake-cased) as the tag for all its routes. Use `@ApiTag` to set an explicit tag on a controller or a specific method.

```dart
@ApiTag('payments')
@Controller('payments')
class PaymentsController {
  @Get('')
  Future<List<Payment>> list() async { ... }

  @ApiTag('admin')
  @Post('refund')
  Future<void> refund(@Body() RefundRequest req) async { ... }
}
```

In the generated spec, `list` appears under `payments` and `refund` appears under `admin`.

---

## @ApiSummary

Adds a short one-line `summary` field to an operation. Shown as the endpoint title in most OpenAPI UIs.

```dart
@Get(':id')
@ApiSummary('Get a payment by ID')
Future<Payment> getById(@Param() String id) async { ... }
```

---

## @ApiDescription

Adds a `description` field to an operation. Supports Markdown.

```dart
@Post('refund')
@ApiDescription('''
Issues a full or partial refund for a completed payment.

The original payment must have a status of `completed` before
a refund can be issued.
''')
Future<Refund> refund(@Body() RefundRequest req) async { ... }
```

---

## @ApiResponse

Documents additional response codes beyond the default. Useful for error responses that are handled by middleware or exception handlers outside the method body.

```dart
@Get(':id')
@ApiResponse(404, description: 'Payment not found')
@ApiResponse(403, description: 'Insufficient permissions')
Future<Payment> getById(@Param() String id) async { ... }
```

:::note
When `@ApiResponse` annotations are present, they **replace** the auto-generated success response in the spec. Add an explicit `@ApiResponse` for the success code if you want it included.
:::

```dart
@Get(':id')
@ApiResponse(200, description: 'The payment object')
@ApiResponse(404, description: 'Payment not found')
Future<Payment> getById(@Param() String id) async { ... }
```

---

## @ApiHidden

Excludes a controller or method from the generated spec. The endpoint still exists and handles requests — it just does not appear in the documentation.

```dart
// Entire controller is hidden.
@ApiHidden()
@Controller('internal')
class InternalController { ... }

// A single method is hidden.
@Controller('users')
class UsersController {
  @Get('')
  Future<List<User>> list() async { ... }

  @ApiHidden()
  @Get('debug')
  Future<Map<String, dynamic>> debug() async { ... }
}
```

The constant `apiHidden` is provided as a convenience for use without parentheses:

```dart
@apiHidden
@Get('debug')
Future<Map<String, dynamic>> debug() async { ... }
```

---

## @ApiType

Overrides the JSON Schema inferred from a Dart type. Use this on method parameters or on fields of model classes when the inferred schema is incorrect or cannot be resolved.

```dart
@Get('events')
Future<List<Event>> listEvents(
  @Query()
  @ApiType(type: 'integer', format: 'int64')
  Duration maxAge,
) async { ... }
```

### Common Use Cases

**`Duration`** — not a standard JSON type; represent as milliseconds:

```dart
@ApiType(type: 'integer', format: 'int64')
Duration timeout
```

**Custom serialized type** — a class serialized as a plain string:

```dart
@ApiType(type: 'string')
EmailAddress email
```

**Opaque `Object` / `dynamic`** — acknowledge that any JSON value is accepted:

```dart
@ApiType(type: 'object')
Object metadata
```

**External type you don't control** — specify the schema explicitly:

```dart
@ApiType(type: 'string', format: 'date')
LocalDate date
```

See [Type Inference](./type-inference) for the full table of Dart types and their automatically inferred schemas.
