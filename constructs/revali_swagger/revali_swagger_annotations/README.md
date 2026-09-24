# Revali Swagger Annotations

Optional annotations for the [`revali_swagger`][revali-swagger] construct: `@ApiInfo`, `@ApiTag`, `@ApiSummary`, `@ApiDescription`, `@ApiResponse`, `@ApiHidden` and `@ApiType`. They only change the generated OpenAPI spec, never request handling.

## Installation

```bash
dart pub add revali_swagger_annotations
dart pub add --dev revali_swagger
```

## Usage

```dart
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

@Get(':id')
@ApiSummary('Get a user by ID')
@ApiResponse(404, description: 'User not found')
Future<User> getById(@Param() String id) async => ...;
```

## Documentation

[docs.revali.dev/constructs/revali_swagger/annotations](https://docs.revali.dev/constructs/revali_swagger/annotations)

[revali-swagger]: https://pub.dev/packages/revali_swagger
