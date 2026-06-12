---
title: Configuration
sidebar_position: 1
description: Configure the API title, version, and description
---

# Configuration

All options are set in `revali.yaml` under the construct entry. Every option is optional — the construct produces a valid spec with no configuration at all.

## Options

| Option        | Type     | Default   | Description                          |
| ------------- | -------- | --------- | ------------------------------------ |
| `title`       | `String` | `'API'`   | API title in the spec `info` block   |
| `version`     | `String` | `'1.0.0'` | API version                          |
| `description` | `String` | —         | Optional description added to `info` |

## Example

```yaml title="revali.yaml"
constructs:
  - package: revali_swagger
    path: lib/swagger.dart
    options:
      title: My API
      version: 2.1.0
      description: Public API for the My App service
```

The construct always writes both `.revali/revali_swagger/swagger.yaml` and `.revali/revali_swagger/swagger.json`.

## Overriding with @ApiInfo

The `@ApiInfo` annotation on your Revali app class overrides the `title`, `version`, and `description` values from `revali.yaml`:

```dart title="lib/main.dart"
import 'package:revali_router/revali_router.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

@ApiInfo(
  title: 'My API',
  version: '2.1.0',
  description: 'Public API for the My App service',
)
@App(host: 'localhost', port: 8080)
void main() async { ... }
```

:::note
`@ApiInfo` and `revali.yaml` options serve the same purpose. Use `revali.yaml` when you want the config in one place alongside other construct settings. Use `@ApiInfo` when you want the info colocated with your app class.
:::
