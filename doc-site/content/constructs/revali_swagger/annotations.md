---
title: Annotations
description: Optional annotations from revali_swagger_annotations that add summaries, tags, responses and schema overrides to the generated spec
---

These annotations come from `revali_swagger_annotations` (add it to `dependencies`) and only affect the generated spec, never request handling. None are required.

```dart
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';
```

| Annotation | Put it on | Effect |
| --- | --- | --- |
| `@ApiInfo(title:, version:, description:)` | App class | Sets the `info` block, overriding `revali.yaml` |
| `@ApiTag(name)` | Controller or method | Sets the operation's tag(s) |
| `@ApiSummary(text)` | Method | Sets `summary` |
| `@ApiDescription(text)` | Method | Sets `description` (Markdown) |
| `@ApiResponse(code, description:)` | Method, repeatable | Replaces the generated responses |
| `@ApiHidden()` / `@apiHidden` | Controller or method | Leaves it out of the spec |
| `@ApiType(type, format:)` | Handler parameter or model field | Replaces the inferred schema |

## @ApiInfo

Place it on the `@App` class. Values here win over the `revali.yaml` options. With [flavors](/revali/app-configuration/create-an-app#flavors), the app matching the current flavor is used.

<CodeFile name="routes/apps/main_app.dart">

```dart
import 'package:revali_router/revali_router.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

@ApiInfo(
  title: 'Payments API',
  version: '3.0.0',
  description: 'Handles payment processing.',
)
@App()
final class MainApp extends AppConfig {
  const MainApp() : super(host: 'localhost', port: 8080);
}
```

</CodeFile>

## @ApiTag

By default every operation gets one tag: the controller class name without `Controller`, lowercased (`PaymentsController` becomes `payments`). `@ApiTag` on the controller changes it for all its methods. `@ApiTag` on a method replaces the controller's tag for that method, and can be repeated to give the method several tags.

```dart
@ApiTag('billing')
@Controller('payments')
class PaymentsController {
  const PaymentsController();

  @Get()
  Future<List<Payment>> list() async => ...; // tag: billing

  @ApiTag('admin')
  @Post('refund')
  Future<void> refund(@Body() RefundRequest req) async => ...; // tag: admin
}
```

## @ApiSummary and @ApiDescription

```dart
@Get(':id')
@ApiSummary('Get a payment by ID')
@ApiDescription('''
Returns the payment, including its refund history.

Requires the `payments:read` scope.
''')
Future<Payment> getById(@Param() String id) async => ...;
```

## @ApiResponse

With no `@ApiResponse`, the spec has one response: the `@StatusCode` (or `200`) with the return type's schema. Once you add any `@ApiResponse`, **only** your annotations are emitted, each with a description and no schema. Include the success code if you still want it listed.

```dart
@Get(':id')
@ApiResponse(200, description: 'The payment')
@ApiResponse(404, description: 'Payment not found')
@ApiResponse(403, description: 'Missing payments:read scope')
Future<Payment> getById(@Param() String id) async => ...;
```

## @ApiHidden

The endpoint still works. It is just left out of the spec. A controller whose methods are all hidden disappears entirely.

```dart
@ApiHidden()
@Controller('internal')
class InternalController { ... }

@Controller('users')
class UsersController {
  const UsersController();

  @apiHidden
  @Get('debug')
  Future<Map<String, dynamic>> debug() async => ...;
}
```

## @ApiType

Overrides the schema of a handler parameter or of a field on a model class. The first argument is the JSON Schema `type`, and `format` is optional.

```dart
@Get('events')
Future<List<Event>> list(
  @Query() @ApiType('integer', format: 'int64') Duration maxAge,
) async => ...;

class Event {
  const Event({required this.id, required this.timeout});

  final String id;

  @ApiType('integer', format: 'int64')
  final Duration timeout; // milliseconds on the wire
}
```

Use it for `Duration`, value types serialized as strings (`@ApiType('string') EmailAddress email`), and third-party types the generator cannot introspect. See [Type Inference](/constructs/revali_swagger/type-inference#when-apitype-is-needed).
